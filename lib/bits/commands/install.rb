require 'bits/command'
require 'bits/logging'

require 'highline'

module Bits
  define_command :install, :desc => 'Install a package' do
    include Bits::Logging

    def setup(opts)
      ns[:force] = false
      ns[:compiled] = nil

      opts.banner = "Usage: bits install <bit>"
      opts.on('--[no-]compiled', "Insist on installing an already compiled variant or not") do |v|
        ns[:compiled] = v
      end

      opts.on('--force', "Insist on installing even if packages already installed") do |v|
        ns[:force] = v
      end
    end

    def entry(args)
      if args.empty? then
        puts parser.help
        return 1
      end

      atom = args[0]

      repository = ns[:repository]

      parameters = {}
      parameters[:compiled] = ns[:compiled] if ns.has_key? :compiled

      p = repository.find_package atom, parameters

      if p.installed? and not ns[:force]
        log.info "Already installed '#{atom}' using provider(s): #{p.providers_s}"
        return 0
      end

      matching = p.matching_ppps

      raise "No matching PPP could be found" if matching.empty?

      ppp = pick_one atom, matching

      install_ppp atom, ppp
      return 0
    end

    def pick_one(atom, matching)
      return matching[0] if matching.size == 1

      hl = HighLine.new $stdin

      hl.choose do |menu|
        menu.prompt = "Which provider would you like to install '#{atom}' with?"
        matching.each do |match|
          menu.choice(match.provider.provider_id) { match }
        end
      end
    end

    def install_ppp(atom, ppp)
      provider = ppp.provider
      package = ppp.package

      log.info "Installing '#{atom}' using provider: #{provider.provider_id}"
      provider.install package
    end
  end
end
