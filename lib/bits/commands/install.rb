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

      params = {}
      params[:compiled] = @ns[:compiled] if @ns.has_key? :compiled

      backend = LocalBackend.new './repo'
      repository = Bits::Repository.new @ns[:providers], backend

      p = repository.find_package atom, params

      if p.installed?
        log.info "Already installed '#{p.package.atom}'"
        return 0
      end

      p.install
      return 0
    end
  end
end
