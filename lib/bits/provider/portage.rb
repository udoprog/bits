require 'bits/provider'
require 'bits/command_provider'
require 'bits/package'
require 'bits/logging'
require 'bits/spawn'

require 'json'

module Bits
  define_provider :portage, \
    :desc => "Provides interface to Gentoo Portage" \
  do
    include Bits::Logging
    include Bits::CommandProvider
    include Bits::ExternalInterface

    # bridge command
    EMERGE = 'emerge'

    def self.check
      ok = true
      ok &= self.check_command [EMERGE, '--version'], "EMERGE"
      ok &= self.setup_interface :python, :capabilities => [:portage]
      ok
    end

    def initialize(ns)
      super ns
      @client = interfaces[:python]
    end

    def get_package(package_name)
      type, info = @client.request :portage_info, :package => package_name
      raise "Expected info response but got: #{type}" unless type == :info

      name = info['name']
      installed = info['installed']
      candidate = info['candidate']

      return Bits::Package.new(name, installed, candidate)
    end

    def install_package(package)
      unless run [EMERGE, package.atom]
        raise "Could not install package '#{package.atom}'"
      end
    end

    def remove_package(package)
      unless run [EMERGE, "--unmerge", package.atom]
        raise "Could not remove package '#{package.atom}'"
      end
    end

    def to_s
      "<AptProvider>"
    end
  end
end
