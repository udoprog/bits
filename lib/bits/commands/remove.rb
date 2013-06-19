require 'bits/command'
require 'bits/logging'

module Bits
  define_command :remove, :desc => "Remove a package" do
    include Bits::Logging

    def setup(opts)
      opts.banner = "Usage: bits remove <bit>"
    end

    def entry(args)
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
