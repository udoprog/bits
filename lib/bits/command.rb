require 'optparse'

module Bits
  # Baseclass for commands.
  class Command
    attr_reader :ns

    def setup(opts)
      raise "not implemented: setup"
    end

    def initialize(ns)
      @ns = ns
    end
  end

  class << self
    def commands
      @commands ||= {}
    end

    def define_command(command_id, params={}, &block)
      if commands[command_id]
        raise "Command already defined: #{command_id}" 
      end

      desc = params[:desc] || "(no description)"

      klass = Class.new(Command) do
        @command_id = command_id
        @name = command_id.to_s.capitalize
        @desc = desc

        def to_s
          self.class.to_s
        end

        class << self
          attr_reader :command_id, :name, :desc

          def to_s
            "Bits::#{@name}"
          end
        end
      end

      klass.class_eval(&block)

      commands[command_id] = klass
    end
  end
end
