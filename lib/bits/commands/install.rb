require 'bits/command'
require 'bits/logging'
require 'bits/installer_mixin'

module Bits
  define_command :install, \
    :desc => 'Install a package' \
  do
    include Bits::Logging
    include Bits::InstallerMixin

    def setup(opts)
      ns[:force] = false
      ns[:compiled] = nil

      opts.banner = "Usage: bits #{switch} <bit>"

      opts.on('--[no-]compiled', "Insist on installing an already compiled variant or not") do |v|
        ns[:compiled] = v
      end

      setup_installer_opts opts
    end

    def entry(args)
      if args.empty? then
        puts parser.help
        return 1
      end

      atom = args[0]

      repository = ns[:repository]

      criteria = {
        :compiled => ns[:compiled]
      }

      package = repository.find_package atom, criteria
      install_package package, force=ns[:force]
    end
  end
end
