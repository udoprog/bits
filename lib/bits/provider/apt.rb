require 'bits/provider'
require 'bits/package'
require 'bits/logging'

HAS_APT_NATIVE_EXT = begin
  require 'bits/apt_ext'
  true
rescue LoadError
  false
end

module Bits
  class AptProvider < Provider
    include Bits::Logging

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

    def to_s
      "<AptProvider>"
    end
  end
end
