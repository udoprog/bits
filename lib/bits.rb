require 'optparse'

require 'bits/backend/local'
require 'bits/backend/join'
require 'bits/package'
require 'bits/repository'

require 'bits/commands/install'
require 'bits/commands/remove'
require 'bits/commands/show'
require 'bits/commands/sync'

require 'bits/provider/python'
require 'bits/provider/apt'
require 'bits/provider/portage'
require 'bits/provider/homebrew'

require 'bits/external_interface'
require 'bits/user'

module Bits
  class << self
    def parse_options(args)
      ns = {}

      subcommands = Hash.new
      available_providers = Array.new
      unavailable_providers = Array.new

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

        Bits.commands.values.sort_by{|c| c.command_id.to_s}.each do |klass|
          global_opts.separator "  #{klass.command_id}: #{klass.desc}"

          parser = OptionParser.new do |opts|
            klass.setup(opts)
          end

          subcommands[klass.command_id] = [klass, parser]
        end

        Bits.providers.values.sort_by{|p| p.provider_id.to_s}.each do |provider_class|
          if provider_class.check
            available_providers << provider_class
          else
            unavailable_providers << provider_class
          end
        end

        global_opts.separator "Providers:"

        available_providers.each do |provider_class|
          global_opts.separator "  #{provider_class.provider_id}: #{provider_class.desc}"
        end

        global_opts.separator "Unavailable providers:"
        unavailable_providers.each do |klass|
          global_opts.separator "  #{klass.provider_id}: #{klass.last_check_error}"
        end
      end

      global.order!
      command = ARGV.shift

      if command.nil? then
        $stderr.puts global.help
        exit 0
      end

      command = command.to_sym

      if subcommands[command].nil? then
        $stderr.puts "No such command: #{command}"
        $stderr.puts global.help
        exit 0
      end

      command_klass, parser = subcommands[command]
      parser.order!

      ns[:user] = setup_user
      ns[:local_repository_dir] = setup_local_repository_dir ns

      command = command_klass.new ns
      providers = setup_providers available_providers, ns
      backend = setup_backend ns

      ns[:repository] = Bits::Repository.new(providers, backend)

      return ARGV, command
    end

    # Setup the path to the local repository directory.
    def setup_local_repository_dir(ns)
      home = ENV['HOME']
      raise "HOME environment variable not defined" if home.nil?
      File.join home, '.bits'
    end

    def setup_logging
      log = Log4r::Logger.new 'Bits'
      log.outputters << Log4r::Outputter.stdout
      log.level =  Log4r::INFO
      log
    end

    def setup_providers(available_providers, ns)
      available_providers.collect do |provider_class|
        provider_class.new ns
      end
    end

    def setup_backend(ns)
      cwd_dir = File.join Dir.pwd, 'bits'
      local_dir = ns[:local_repository_dir]

      backends = Array.new

      backends << LocalBackend.new(cwd_dir) if File.directory? cwd_dir
      backends << LocalBackend.new(local_dir) if File.directory? local_dir

      raise "Bits backends available" if backends.empty?

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
