require 'bits/provider'

HAS_EXT = begin
  require 'bits/apt_ext'
  true
rescue
  false
end

module Bits
  class AptProvider < Provider
    provider_id :apt
    provider_doc "Provides interface for Debian APT"

    def self.initialize!
      return false unless HAS_EXT
      return false unless Apt::initialize
      true
    end

    def get_version(package)
      result = Apt::Cache::policy(package)
      return nil if result.empty?
      return result[0].current_version.version
    end
  end
end
