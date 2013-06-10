module Bits
  class Command
    class << self
      def inherited(o)
        commands << o
      end

      def commands
        @commands ||= []
      end

      def command_name(name)
        @name = name
      end

      def name
        raise "Command must have 'command_name' specified" if @name.nil?
        @name
      end
    end

    def name
      self.class.name
    end

    def parser
      raise "not implemented: parser"
    end

    def self.register(subcommands, ns)
      commands.each do |command|
        c = command.new ns
        subcommands[c.name] = c
      end
    end
  end
end
