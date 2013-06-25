require 'bits/logging'
require 'bits/command_provider'
require 'bits/external_interface'
require 'bits/provider_reporting'
require 'bits/cache'

module Bits
  define_provider :npm, \
    :name => 'NPM',
    :desc => "Provider for Node Packaged Modules (npm)" \
  do
    include Bits::Logging
    include Bits::CommandProvider
    include Bits::ExternalInterface
    include Bits::ProviderReporting
    include Bits::Cache

    NPM = 'npm'

    def self.check
      unless self.setup_interface :node, :capabilities => [:npm]
        check_error "Could not setup required interface"
        return false
      end

      log.debug "npm is available"
      true
    end

    def setup
      @client = interfaces[:node]
      @cache = setup_cache ns[:bits_dir], provider_id
    end

    def sync
      log.warn "NPM does not know how to sync yet"
    end

    def query(atom)
      type, info = @client.request :npm_view, \
        :package => atom

      raise MissingPackage.new atom if type == :missing_package
      raise "Expected info response but got: #{type}" unless type == :info

      installed = info['installed']

      candidate = if candidate.nil?
        info['candidate']
      else
        candidate['version']
      end

      Bits::Package.new(atom, installed, candidate)
    end

    def install(package)
      execute do
        unless run [NPM, 'install', package.atom]
          raise "Could not install package '#{package.atom}'"
        end
      end
    end

    def remove(package)
      execute do
        unless run [NPM, 'uninstall', package.atom]
          raise "Could not remove package '#{package.atom}'"
        end
      end
    end
  end
end
