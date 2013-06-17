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

    def info(atom)
      raise "not implemented: info"
    end

    def install(atom)
      raise "not implemented: install"
    end

    def remove(atom)
      raise "not implemented: remove"
    end
  end

  class << self
    def providers
      @providers ||= {}
    end

    def define_provider(id, params={}, &block)
      raise "Provider already defined: #{id}" if providers[id]

      desc = params[:desc] || "(no description)"

      klass = Class.new Provider do
        @id = id
        @name = id.to_s.capitalize
        @desc = desc

        class << self
          attr_reader :id, :desc, :name

          def to_s
            "Bits::Provider::#{@name}"
          end
        end
      end

      klass.class_eval(&block)

      providers[id] = klass
    end
  end
end
