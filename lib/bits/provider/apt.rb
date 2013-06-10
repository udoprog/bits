require 'bits/provider'
require 'bits/package'
require 'bits/logging'
require 'bits/spawn'

HAS_APT_NATIVE_EXT = begin
  require 'bits/apt/apt_ext'
  true
rescue LoadError
  false
end

module Bits
  class AptProvider < Provider
    include Bits::Logging

    APT_GET = 'apt-get'

    provider_id :apt
    provider_doc "Provides interface for Debian APT"

    def self.initialize!
      unless HAS_APT_NATIVE_EXT
        log.debug "Could not require APT native extension"
        return false
      end

      unless Apt::initialize
        log.debug "Could not initialize APT native extension"
        return false
      end

      log.debug "APT native extension are initialized"
      true
    end

    def get_package(package_name)
      result = Apt::Cache::policy(package_name)

      raise MissingPackage.new package_name if result.empty?
      raise "Too many packages '#{package_name}'" if result.size > 1

      p = result[0]

      current = nil
      candidate = nil

      current = p.current.version if p.current
      candidate = p.candidate.version if p.candidate

      return Bits::Package.new(p.name, current, candidate)
    end

    def install_package(package)
      exit_code = Bits.spawn [APT_GET, 'install', package.atom]
      raise "Could not install package '#{package.atom}'" unless exit_code == 0
    end

    def remove_package(package)
      exit_code = Bits.spawn [APT_GET, 'remove', package.atom]
      raise "Could not remove package '#{package.atom}'" unless exit_code == 0
    end

    def to_s
      "<AptProvider>"
    end
  end
end
