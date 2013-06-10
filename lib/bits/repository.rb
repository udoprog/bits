require 'bits/logging'
require 'bits/bit_declaration'
require 'bits/bit'
require 'bits/package_proxy'

module Bits
  class Repository
    include Bits::Logging

    attr_accessor :providers, :backend

    def initialize(providers, backend)
      @providers = providers
      @backend = backend
    end

    def find_package(atom, criteria={})
      all_packages = []

      bit = iterate_packages(atom) do |provider, params|
        begin
          package = provider.get_package(params[:atom])
        rescue MissingPackage
          next
        end

        all_packages << [provider, package, params]
      end

      if all_packages.empty?
        log.warn "Could not find atom '#{atom}' with criteria #{criteria.inspect}"
        raise MissingProvidedPackage.new atom
      end

      return PackageProxy.new bit, all_packages, criteria
    end

    private

    def load_bit(atom)
      reader = backend.fetch(atom)
      Bit.eval reader, atom
    end

    def find_provider(provider_id)
      providers[provider_id]
    end

    def iterate_packages(atom)
      bit = load_bit atom

      bit.provider_ids.each do |provider_id|
        provider = find_provider provider_id

        if provider.nil? then
          log.debug "No such provider: #{provider_id}"
          next
        end

        params = bit.get_params provider_id

        yield [provider, params]
      end

      bit
    end
  end
end
