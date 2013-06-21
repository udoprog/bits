require 'optparse'

require 'bits/backend/join'
require 'bits/backend/local'
require 'bits/external_interface'
require 'bits/logging'
require 'bits/package'
require 'bits/repository'
require 'bits/user'

require 'bits/commands/install'
require 'bits/commands/remove'
require 'bits/commands/setup'
require 'bits/commands/show'
require 'bits/commands/sync'
require 'bits/commands/query'
require 'bits/commands/manifest'
require 'bits/commands/query_provider'
require 'bits/commands/sync_provider'

require 'bits/provider/apt'
require 'bits/provider/homebrew'
require 'bits/provider/portage'
require 'bits/provider/python'
require 'bits/provider/rubygems'

module Bits
  class << self
    include Bits::Logging

    DEFAULT_COMMAND = 'manifest'

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
          global_opts.separator "  #{klass.switch}: #{klass.desc}"
          subcommands[klass.switch] = klass
        end

        Bits.providers.values.sort_by{|p| p.provider_id.to_s}.each do |klass|
          if klass.check
            available_providers << klass
          else
            unavailable_providers << klass
          end
        end

        global_opts.separator "Providers:"

        available_providers.each do |klass|
          global_opts.separator "  #{klass.provider_id}: #{klass.desc}"
        end

        global_opts.separator "Unavailable providers:"
        unavailable_providers.each do |klass|
          global_opts.separator "  #{klass.provider_id}: #{klass.last_check_error}"
        end
      end

      global.order!
      command = ARGV.shift

      command = DEFAULT_COMMAND if command.nil?

      if command.nil? then
        $stderr.puts global.help
        exit 0
      end

      if subcommands[command].nil? then
        $stderr.puts "No such command: #{command}"
        $stderr.puts global.help
        exit 0
      end

      bits_dir = setup_bits_dir
      repo_dir = setup_repo_dir bits_dir
      backend = setup_backend repo_dir

      ns[:user] = setup_user
      ns[:bits_dir] = bits_dir
      ns[:repo_dir] = repo_dir

      providers = setup_providers available_providers, ns
      repository = Bits::Repository.new(providers, backend)

      ns[:providers] = providers
      ns[:repository] = repository

      command_klass = subcommands[command]
      command = command_klass.new ns

      command_parser = OptionParser.new do |opts|
        command.setup opts
      end

      command_parser.order!

      return ARGV, command, command_parser
    end

    def setup_bits_dir
      home = ENV['HOME']
      raise "HOME environment variable not defined" if home.nil?
      bits_dir = File.join home, '.bits'
      FileUtils.mkdir_p bits_dir unless File.directory? bits_dir
      bits_dir
    end

    # Setup the path to the local repository directory.
    def setup_repo_dir(bits_dir)
      File.join bits_dir, 'bits'
    end

    def setup_logging
      log = Log4r::Logger.new 'Bits'
      log.outputters << Log4r::Outputter.stdout
      log.level =  Log4r::INFO
      log
    end

    def setup_providers(available_providers, ns)
      available_providers.collect do |klass|
        provider = klass.new ns
        provider.setup
        provider
      end
    end

    def setup_backend(local_dir)
      cwd_dir = File.join Dir.pwd, 'bits'

      backends = Array.new

      backends << LocalBackend.new(cwd_dir) if File.directory? cwd_dir
      backends << LocalBackend.new(local_dir) if File.directory? local_dir

      JoinBackend.new backends
    end

    def main(args)
      @log = setup_logging

      args, command, command_parser = parse_options(args)

      begin
        command.entry args
      rescue InvalidArgument => e
        $stderr.puts "Argument Error: #{e}"
        $stderr.puts command_parser.help
        return 1
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
