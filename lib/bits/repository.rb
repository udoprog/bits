require 'bits/logging'
require 'bits/bit_declaration'
require 'bits/bit'
require 'bits/package_proxy'
require 'bits/exceptions'

module Bits
  class PPP
    attr_accessor :bit, :provider, :package, :params

    def initialize(bit, provider, package, params)
      @bit = bit
      @provider = provider
      @package = package
      @params = params
    end
  end

  class Repository
    include Bits::Logging

    attr_accessor :providers, :backend

    def initialize(providers, backend)
      @cache = {}
      @providers = providers
      @backend = backend
    end

    def check_dependencies(package_proxy)
      package_proxies = {}

      dependencies = package_proxy.dependencies

      while not dependencies.empty?
        more_dependencies = {}

        dependencies.each do |atom, params|
          next if package_proxies.has_key? atom
          proxy = find_package(atom, params)
          package_proxies[atom] = proxy
          more_dependencies.merge! proxy.dependencies
        end

        dependencies = more_dependencies
      end

      package_proxies
    end

    def find_package(atom, criteria={})
      ppps = []

      iterate_packages(atom) do |bit, provider, params|
        begin
          package = provider.get_package(params[:atom])
        rescue MissingPackage
          next
        end

        ppps << PPP.new(bit, provider, package, params)
      end

      if ppps.empty?
        log.warn "Could not find atom '#{atom}' with criteria #{criteria.inspect}"
        raise MissingProvidedPackage.new atom
      end

      return PackageProxy.new ppps, criteria
    end

    private

    def load_bit(atom)
      return @cache[atom] unless @cache[atom].nil?
      reader = backend.fetch(atom)
      @cache[atom] = Bit.eval reader, atom
    end

    def find_provider(provider_id)
      providers[provider_id]
    end

    def iterate_packages(atom)
      bit = load_bit atom
      bits = [[bit, []]]

      while not bits.empty?
        current_bit, path = bits.shift

        path << current_bit.atom

        current_bit.provider_ids.each do |provider_id|
          provider = find_provider provider_id

          if provider.nil? then
            log.debug "No such provider: #{provider_id}"
            next
          end

          params = current_bit.get_provides provider_id

          raise "Not provided: #{provider_id}" if params.nil?

          if params.kind_of? String
            raise "Circular reference" if path.include? params
            next_bit = load_bit params
            bits << [next_bit, Array.new(path)]
            next
          end

          params = {
            :atom => (params[:atom] || current_bit.atom),
            :compiled => (params[:compiled] || false),
          }

          yield [current_bit, provider, params]
        end
      end
    end
  end
end
