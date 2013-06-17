require 'bits/provider'
require 'bits/command_provider'
require 'bits/spawn'
require 'bits/package'
require 'bits/logging'
require 'bits/exceptions'

require 'bits/external_interface'

require "xmlrpc/client"

module Bits
  define_provider :python,
    :desc => "Provides interface for Python Packages" \
  do
    include Bits::Logging
    include Bits::CommandProvider
    include Bits::ExternalInterface

    PIP = 'pip'
    INDEX = 'https://pypi.python.org/pypi'

    def self.check
      ok = true
      ok &= self.check_command [PIP, '--version'], 'PIP'
      ok &= self.setup_interface :python, :capabilities => [:pkg_resources]
      ok
    end

    def initialize(ns)
      super ns
      @client = XMLRPC::Client.new_from_uri(INDEX)
      @client.http_header_extra = {'Content-Type' => 'text/xml'}
      @python = self.class.interfaces[:python]
    end

    def get_installed_version(package_atom)
      type, response = @python.request :python_info, :atom => package_atom
      return nil if type == :missing_atom
      response['installed']
    end

    def get_candidate_version(package_atom)
      begin
        result = @client.call(:package_releases, package_atom)
      rescue SocketError
        return nil
      end

      raise MissingPackage.new package_atom if result.empty?
      return result[0]
    end

    def get_package(package_atom)
      candidate = get_candidate_version package_atom
      current = get_installed_version package_atom
      return Bits::Package.new(package_atom, current, candidate)
    end

    def install_package(package)
      exit_code = Bits.spawn [PIP, 'install', package.atom]
      raise "Could not install package '#{package.atom}'" unless exit_code == 0
    end

    def remove_package(package)
      exit_code = Bits.spawn [PIP, 'uninstall', package.atom]
      raise "Could not remove package '#{package.atom}'" unless exit_code == 0
    end

    def to_s
      "<PipProvider>"
    end
  end
end
