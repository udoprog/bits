require 'bits/execute_context'

module Bits
  class Provider
    class << self
      # Override to provide custom static initialization code for provider.
      # Should return true if the specified provider can be used in this system.
      def check
        true
      end
    end

    attr_reader :ns

    def initialize(ns)
      @ns = ns
    end

    def setup
      raise "not implemented: setup"
    end

    def sync
      raise "not implemented: sync"
    end

    def query(atom)
      raise "not implemented: query"
    end

    def install(atom)
      raise "not implemented: install"
    end

    def remove(atom)
      raise "not implemented: remove"
    end

    def execute(&block)
      raise "Missing user from namespace" if ns[:user].nil?
      context = ExecuteContext.new ns[:user]
      return context.instance_eval(&block)
    end
  end

  class << self
    def providers
      @providers ||= {}
    end

    def define_provider(provider_id, params={}, &block)
      if providers[provider_id]
        raise "Provider already defined: #{provider_id}"
      end

      desc = params[:desc] || "(no description)"

      klass = Class.new Provider do
        @provider_id = provider_id
        @name = provider_id.to_s.capitalize
        @desc = desc

        def to_s
          self.class.to_s
        end

        def provider_id
          self.class.provider_id
        end

        class << self
          attr_reader :provider_id, :desc, :name

          def to_s
            "Bits::Provider::#{@name}"
          end
        end
      end

      klass.class_eval(&block)

      providers[provider_id] = klass
    end
  end
end
