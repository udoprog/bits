require 'bits/provider'
require 'bits/provider_reporting'
require 'bits/package'
require 'bits/logging'
require 'bits/spawn'
require 'bits/exceptions'

require 'bits/command_provider'

HAS_APT_NATIVE_EXT = begin
  require 'apt/apt_ext'
  true
rescue LoadError
  false
end

module Bits
  define_provider :apt, \
    :desc => "Provides interface for Debian APT" \
  do
    include Bits::Logging
    include Bits::CommandProvider
    include Bits::ProviderReporting

    APT_GET = 'apt-get'

    def self.check
      unless HAS_APT_NATIVE_EXT
        check_error "APT native extension could not be loaded"
        return false
      end

      unless Apt::initialize
        check_error "APT native extension could not be initialized"
        return false
      end

      log.debug "APT native extension is available"
      true
    end

    def setup; end

    def sync
      execute do
        unless run [APT_GET, 'update']
          raise "Could not update apt provider"
        end
      end
    end

    def query(atom)
      result = Apt::Cache::policy(atom)

      raise MissingPackage.new atom if result.empty?
      raise "Too many packages '#{atom}'" if result.size > 1

      package = result[0]

      current = nil
      candidate = nil

      current = package.current.version if package.current
      candidate = package.candidate.version if package.candidate

      return Bits::Package.new(package.name, current, candidate)
    end

    def install(package)
      execute do
        unless run [APT_GET, 'install', package.atom], :superuser => true
          raise "Could not install package '#{package.atom}'"
        end
      end
    end

    def remove(package)
      execute do
        unless run [APT_GET, 'remove', package.atom], :superuser => true
          raise "Could not remove package '#{package.atom}'"
        end
      end
    end
  end
end
