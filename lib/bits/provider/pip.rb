require 'bits/provider'
require 'bits/spawn'
require 'bits/package'
require 'bits/logging'

require "xmlrpc/client"

module Bits
  class PipProvider < Provider
    include Bits::Logging

    PYPI = 'https://pypi.python.org/pypi'
    VERSION_REGEXP = /^Version: (.+)$/

    provider_id :pip
    provider_doc "Provides interface for Python pip"

    def self.initialize!
      begin
        exit_code = Bits.spawn ['pip', '--version']
        log.debug "PIP command available"
        true
      rescue Errno::ENOENT
        log.debug "PIP command not available"
        false
      rescue
      end

      if exit_code != 0 then
        log.debug "PIP command could not be invoked"
        return false
      end

      true
    end

    def initialize
      @client = XMLRPC::Client.new_from_uri(PYPI)
      @client.http_header_extra = {'Content-Type' => 'text/xml'}
    end

    def get_installed_version(package_atom)
      Bits.spawn(['pip', 'show', package_atom], :stdout => PIPE) do |out, err|
        out.each_line do |line|
          unless m = VERSION_REGEXP.match(line) then
            next
          end

          return m[1]
        end
      end

      nil
    end

    def get_candidate_version(package_atom)
      result = @client.call(:package_releases, package_atom)
      raise MissingPackage.new package_atom if result.empty?
      return result[0]
    end

    def get_package(package_atom)
      candidate = get_candidate_version package_atom
      current = get_installed_version package_atom
      return Bits::Package.new(package_atom, current, candidate)
    end

    def to_s
      "<PipProvider>"
    end
  end
end
