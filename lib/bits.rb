require 'optparse'

require 'bits/backend/local'
require 'bits/backend/join'
require 'bits/package'
require 'bits/repository'

require 'bits/commands/install'
require 'bits/commands/remove'
require 'bits/commands/show'

require 'bits/provider/python'
require 'bits/provider/apt'
require 'bits/provider/portage'
require 'bits/provider/homebrew'

require 'bits/external_interface'

module Bits
  class << self
    def parse_options(args)
      ns = {}

      subcommands = Hash.new
      available_providers = Array.new

      global = OptionParser.new do |global_opts|
        global_opts.banner = "Usage: bits <command> [options]"

        global_opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
          ns[:verbose] = v
        end

        global_opts.on("-d", "--debug", "Enable debug logging") do |v|
          @log.level = Log4r::DEBUG
        end

        global_opts.separator ""
        global_opts.separator "Available commands:"

        Bits.commands.each do |id, klass|
          global_opts.separator "  #{klass.id}: #{klass.desc}"

          parser = OptionParser.new do |opts|
            klass.setup(opts)
          end

          subcommands[id] = [klass, parser]
        end

        global_opts.separator "Providers:"

        Bits.providers.each do |id, klass|
          if klass.check
            available_providers << klass
            global_opts.separator "  #{klass.id}: #{klass.desc}"
          else
            global_opts.separator "  #{klass.id}: #{klass.desc} (not available)"
          end
        end
      end

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

      command_klass, parser = subcommands[command]
      parser.order!

      command = command_klass.new ns
      providers = setup_providers available_providers, ns
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

    def setup_providers(available_providers, ns)
      instances = Hash.new

      available_providers.each do |klass|
        instances[klass.id] = klass.new ns
      end

      instances
    end

    def setup_backend(ns)
      backends = []
      backends << LocalBackend.new('/usr/lib/bits')
      backends << LocalBackend.new('./bits')
      JoinBackend.new backends
    end

    def main(args)
      @log = setup_logging

      args, command = parse_options(args)

      begin
        command.entry args
      ensure
        Bits::ExternalInterface.close_interfaces
      end

      return 0
    end
  end
end

if __FILE__ == $0
    exit Bits::main(ARGV)
end
