require 'bits/command'
require 'bits/logging'

module Bits
  class InstallCommand < Command
    include Bits::Logging

    command_name :install

    def initialize(ns)
      @ns = ns
    end

    def parser
      @parser ||= OptionParser.new do |opts|
        opts.banner = "Usage: bits install <bit>"
        opts.on('--[no-]compiled', "Insist on installing an already compiled variant or not") do |v|
          @ns[:compiled] = v
        end
      end
    end

    def run(args)
      if args.empty? then
        puts parser.help
        return 1
      end

      atom = args[0]

      repository = @ns[:repository]

      params = {}
      params[:compiled] = @ns[:compiled] if @ns.has_key? :compiled

      p = repository.find_package atom, params

      depends = repository.check_dependencies p
      depends[atom] = p

      depends.each do |atom, p|
        if p.installed?
          log.info "Already installed '#{atom}' using provider(s): #{p.providers_s}"
          next
        end

        p.install
      end

      return 0
    end
  end
end
