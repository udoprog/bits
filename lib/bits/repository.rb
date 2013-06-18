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
          package = provider.get_package(params[:atom])
        rescue MissingPackage
          next
        end

        ppps << PPP.new(bit, provider, package, params, path)
      end

      if ppps.empty?
        log.warn "Could not find atom '#{atom}'"
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
      bit = load_bit atom
      bits = [[bit, [], nil]]

      while not bits.empty?
        current_bit, path, filter = bits.shift

        path << current_bit.atom

        # match all the providers that is specified by the bit and if
        # provider_filter is defined, explicitly match that too.
        matching = providers.select do |p|
          current_bit.provided_by?(p.provider_id) and
          (filter.nil? or filter == p.provider_id)
        end

        raise "No matching providers: #{current_bit}" if matching.empty?

        matching.each do |provider|
          p = current_bit.get_provides provider.provider_id

          if p.kind_of? String
            if path.include? p
              raise "Circular reference: #{path.inspect}"
            end

            next_bit = load_bit p
            bits << [next_bit, Array.new(path), provider.provider_id]
            next
          end

          params = {
            :atom => (p[:atom] || current_bit.atom),
            :compiled => (p[:compiled] || false),
          }

          yield [current_bit, provider, params, path]
        end
      end
    end
  end
end
