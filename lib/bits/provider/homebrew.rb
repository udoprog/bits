require 'bits/logging'
require 'bits/command_provider'
require 'bits/provider_reporting'
require 'bits/external_interface'


HAS_HOMEBREW = begin
  $: << '/usr/local/Library/Homebrew'
  require 'global'
  require 'formula'
  true
rescue LoadError
  $:.replace $old
  false
end

module Bits
  define_provider :homebrew, \
    :desc => "Provides interface for Homebrew" \
  do
    include Bits::Logging
    include Bits::CommandProvider
    include Bits::ProviderReporting
    include Bits::ExternalInterface

    BREW = 'brew'

    def self.check
      unless self.setup_interface :ruby, :capabilities => [:homebrew]
        check_error "Could not setup required interface"
        return false
      end

      log.debug "Homebrew is available"
      true
    end

    def initialize(ns)
      super ns
      @client = interfaces[:ruby]
    end

    def query(atom)
      type, info = @client.request :homebrew_info, :package => atom
      raise MissingPackage.new atom if type == :missing_package
      raise "Expected info response but got: #{type}" unless type == :info
      installed = info['installed']
      candidate = info['candidate']
      Bits::Package.new(atom, installed, candidate)
    end

    def install(package)
      execute do
        unless run [BREW, 'install', package.atom]
          raise "Could not install package '#{package.atom}'"
        end
      end
    end

    def remove(package)
      execute do
        unless spawn [BREW, 'uninstall', package.atom]
          raise "Could not remove package '#{package.atom}'"
        end
      end
    end
  end
end
