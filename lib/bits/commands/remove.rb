require 'bits/command'
require 'bits/logging'

module Bits
  class RemoveCommand < Command
    include Bits::Logging

    command_name :remove

    def initialize(ns)
      @ns = ns
    end

    def parser
      @parser ||= OptionParser.new do |opts|
        opts.banner = "Usage: bits remove <bit>"
      end
    end

    def run(args)
      if args.empty? then
        puts parser.help
        return 1
      end

      atom = args[0]

      repository = @ns[:repository]

      p = repository.find_package atom

      unless p.installed?
        log.info "Package not installed '#{atom}'"
        return 0
      end

      log.info "Removing '#{atom}' using provider(s): #{p.providers_s}"

      p.remove
      return 0
    end
  end
end
