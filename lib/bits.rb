require 'optparse'

require 'bits/provider/pip'
require 'bits/provider/apt'
require 'bits/backend/local'
require 'bits/package'
require 'bits/repository'

require 'bits/commands/install'
require 'bits/commands/remove'

module Bits
  class << self
    def parse_options(args)
      ns = {}

      subtext = <<HELP
Commonly used command are:
  install : Install packages
  remove : Remove packages

See 'bits <command> --help' for more information on a specific command.
HELP

      global = OptionParser.new do |opts|
        opts.banner = "Usage: bits <command> [options]"

        opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
          ns[:verbose] = v
        end

        opts.on("-d", "--debug", "Enable debug logging") do |v|
          @log.level = Log4r::DEBUG
        end

        opts.separator ""
        opts.separator subtext
      end

      subcommands = {}
      Bits::Command.register(subcommands, ns)

      global.order!
      command = ARGV.shift

      if command.nil? then
        puts global.help
        exit 0
      end

      command = command.to_sym

      unless subcommands.has_key?(command) then
        puts global.help
        exit 0
      end

      command = subcommands[command]
      command.parser.order!

      providers = setup_providers ns
      backend = setup_backend ns

      ns[:repository] = Bits::Repository.new(providers, backend)

      return ARGV, command
    end

    def setup_logging
      log = Log4r::Logger.new 'Bits'
      log.outputters << Log4r::Outputter.stdout
      log.level =  Log4r::INFO
      log
    end

    # Initialize all available providers and return an array containing an
    # instance of them.
    def setup_providers(ns)
      providers = Hash.new

      Provider.providers.each do |p|
        next unless p.initialize!
        providers[p.id] = p.new
      end

      return providers
    end

    def setup_backend(ns)
      LocalBackend.new '/usr/lib/bits'
    end

    def main(args)
      @log = setup_logging

      args, command = parse_options(args)

      command.run args
      return 0
    end
  end
end

if __FILE__ == $0
    exit Bits::main(ARGV)
end
