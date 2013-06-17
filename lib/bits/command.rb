require 'optparse'

module Bits
  class << self
    def commands
      @commands ||= {}
    end

    def define_command(id, &block)
      raise "Already defined: #{id}" if commands[id]

      klass = Class.new(Command) do
        @id = id.to_s.capitalize

        def self.id
          @id
        end

        def self.to_s
          "Bits::#{@id}"
        end
      end

      klass.class_eval(&block)

      commands[id] = klass
    end

    def register_commands(subcommands, ns)
      commands.each do |id, klass|
        parser = OptionParser.new do |opts|
          klass.setup(opts)
        end

        command = klass.new ns
        subcommands[id] = [command, parser]
      end
    end
  end

  class Command
    attr_reader :ns

    def initialize(ns)
      @ns = ns
    end
  end
end
