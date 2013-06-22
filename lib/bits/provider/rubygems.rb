require 'bits/logging'
require 'bits/command_provider'
require 'bits/external_interface'
require 'bits/provider_reporting'
require 'bits/cache'

module Bits
  define_provider :rubygems, \
    :desc => "Provides interface for Rubygems" \
  do
    include Bits::Logging
    include Bits::CommandProvider
    include Bits::ExternalInterface
    include Bits::ProviderReporting
    include Bits::Cache

    GEM = 'gem'

    def self.check
      unless self.setup_interface :ruby, :capabilities => [:rubygems]
        check_error "Could not setup required interface"
        return false
      end

      log.debug "rubygems is available"
      true
    end

    def setup
      @client = interfaces[:ruby]
      @cache = setup_cache ns[:bits_dir], provider_id
    end

    def sync
      type, response = @client.request :rubygems_candidates

      unless type == :candidates
        raise "Expected rubygems_candidate response but got: #{type}"
      end

      candidates = response['candidates']

      log.info "Syncing #{candidates.size} gems"

      cache = candidates.inject({}){|h, i| h[i['atom']] = i; h}

      @cache.set cache
      @cache.save
    end

    def query(atom)
      candidate = @cache[atom]

      type, info = @client.request :rubygems_info, \
        :package => atom, \
        :remote => candidate.nil?

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
        unless run [GEM, 'install', package.atom]
          raise "Could not install package '#{package.atom}'"
        end
      end
    end

    def remove(package)
      execute do
        unless run [GEM, 'uninstall', package.atom]
          raise "Could not remove package '#{package.atom}'"
        end
      end
    end
  end
end
