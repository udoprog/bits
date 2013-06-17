require 'optparse'

module Bits
  class Command
    attr_reader :ns

    def initialize(ns)
      @ns = ns
    end
  end

  class << self
    def commands
      @commands ||= {}
    end

    def define_command(id, params={}, &block)
      desc = params[:desc] || "(no description)"

      raise "Already defined: #{id}" if commands[id]

      klass = Class.new(Command) do
        @id = id
        @name = id.to_s.capitalize
        @desc = desc

        class << self
          attr_reader :id, :name, :desc

          def to_s
            "Bits::#{@name}"
          end
        end
      end

      klass.class_eval(&block)

      commands[id] = klass
    end
  end
end
