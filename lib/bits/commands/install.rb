require 'bits/command'
require 'bits/logging'

module Bits
  define_command :install, :desc => 'Install a package' do
    include Bits::Logging

    def self.setup(opts)
      opts.banner = "Usage: bits install <bit>"
      opts.on('--[no-]compiled', "Insist on installing an already compiled variant or not") do |v|
        ns[:compiled] = v
      end
    end

    def entry(args)
      if args.empty? then
        puts parser.help
        return 1
      end

      atom = args[0]

      repository = ns[:repository]

      params = {}
      params[:compiled] = ns[:compiled] if ns.has_key? :compiled

      p = repository.find_package atom, params

      depends = repository.check_dependencies p
      depends[atom] = p

      depends.each do |atom, p|
        if p.installed?
          log.info "Already installed '#{atom}' using provider(s): #{p.providers_s}"
          next
        end

        log.info "Installing '#{atom}' using provider(s): #{p.providers_s}"
        p.install
      end

      return 0
    end
  end
end
