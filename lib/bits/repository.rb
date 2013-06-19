require 'bits/logging'
require 'bits/bit_declaration'
require 'bits/bit'
require 'bits/package_proxy'
require 'bits/exceptions'

module Bits
  class PPP
    attr_accessor :bit, :provider, :package, :params, :path

    def initialize(bit, provider, package, params, path)
      @bit = bit
      @provider = provider
      @package = package
      @params = params
      @path = path
    end
  end

  class Repository
    include Bits::Logging

    attr_accessor :providers, :backend

    def initialize(providers, backend)
      @bitcache = {}
      @providers = providers
      @backend = backend
    end

    def find_package(atom, criteria={})
      ppps = []

      iterate_packages(atom) do |bit, provider, params, path|
        begin
          package = provider.query(params[:atom])
        rescue MissingPackage
          log.warn "No such atom '#{params[:atom]}' for provider '#{provider.provider_id}'"
          next
        end

        ppps << PPP.new(bit, provider, package, params, path)
      end

      if ppps.empty?
        raise MissingProvidedPackage.new atom
      end

      return PackageProxy.new ppps, criteria
    end

    private

    def load_bit(atom)
      log.debug "Loading bit: #{atom}"
      return @bitcache[atom] unless @bitcache[atom].nil?
      reader = backend.fetch(atom)
      @bitcache[atom] = Bit.eval reader, atom
    end

    def iterate_packages(atom)
      references = [[[], atom, nil]]

      while not references.empty?
        path, atom, filter = references.shift

        if path.include? atom
          raise "Circular reference: #{path.inspect.join ' -> '}"
        end

        current_bit = load_bit atom

        path << current_bit.atom

        # match all the providers that is specified by the bit and if
        # provider_filter is defined, explicitly match that too.
        matching = providers.select do |p|
          current_bit.has_provider?(p.provider_id) and
          (filter.nil? or filter == p.provider_id)
        end

        raise "No matching providers: #{current_bit}" if matching.empty?

        # for each matching provider, find the data associated with this
        # provider and bit.
        matching.each do |provider|
          provider_data = current_bit.get_provider_data provider.provider_id

          if provider_data.kind_of? BitReference
            references << [
              Array.new(path),
              provider_data.atom,
              # only match for this specified provider.
              provider.provider_id
            ]

            next
          end

          if provider_data.kind_of? BitParameters
            params = provider_data.parameters

            params = {
              :atom => (params[:atom] || current_bit.atom),
              :compiled => (params[:compiled] || false),
            }

            yield [current_bit, provider, params, path]
            next
          end

          raise "Unknown provider data '#{data}'"
        end
      end
    end
  end
end
