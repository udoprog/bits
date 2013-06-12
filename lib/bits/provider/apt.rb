require 'bits/provider'
require 'bits/package'
require 'bits/logging'
require 'bits/spawn'

require 'bits/command_provider'

HAS_APT_NATIVE_EXT = begin
  require 'apt/apt_ext'
  true
rescue LoadError
  false
end

module Bits
  class AptProvider < Provider
    include Bits::Logging
    include Bits::CommandProvider

    APT_GET = 'apt-get'

    provider_id :apt
    provider_doc "Provides interface for Debian APT"

    def self.initialize!
      unless HAS_APT_NATIVE_EXT
        log.debug "APT native extension not available"
        return false
      end

      unless Apt::initialize
        log.debug "APT native extension could not be initialized"
        return false
      end

      log.debug "APT native extension is available"
      true
    end

    def get_package(package_name)
      result = Apt::Cache::policy(package_name)

      raise MissingPackage.new package_name if result.empty?
      raise "Too many packages '#{package_name}'" if result.size > 1

      package = result[0]

      current = nil
      candidate = nil

      current = package.current.version if package.current
      candidate = package.candidate.version if package.candidate

      return Bits::Package.new(package.name, current, candidate)
    end

    def install_package(package)
      unless run [APT_GET, 'install', package.atom]
        raise "Could not install package '#{package.atom}'"
      end
    end

    def remove_package(package)
      unless Bits.spawn [APT_GET, 'remove', package.atom]
        raise "Could not remove package '#{package.atom}'"
      end
    end

    def to_s
      "<AptProvider>"
    end
  end
end
