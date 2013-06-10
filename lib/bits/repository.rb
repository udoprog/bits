require 'bits/logging'

module Bits
  # Class used to manage state of a bit declaration file.
  class BitDeclaration
    def initialize
      @provider_params = {}
    end

    # Used inside bit declaration.
    def provide(provider_id, criteria={})
      @provider_params[provider_id] = criteria
    end

    def get_provider_params
      @provider_params
    end

    def eval!(path)
      instance_eval(File.new(path).read)
    end

    def self.eval(path)
      decl = self.new
      decl.eval!(path)
      decl
    end
  end

  # Class used to manage a single bit.
  class Bit
    attr_accessor :atom, :path

    def initialize(atom, provider_params)
      @atom = atom
      @provider_params = provider_params
    end

    # List all provider ids that work for this bit.
    def provider_ids
      @provider_params.keys
    end

    def criteria(provider_id)
      p = @provider_params[provider_id]

      return nil if p.nil?

      {
        :atom => (p[:atom] || @atom),
        :compiled => (p[:compiled] || false),
      }
    end

    def self.eval(path, atom)
      decl = BitDeclaration.eval path
      self.new atom, decl.get_provider_params
    end
  end

  class ProvidedPackage
    attr_accessor :provider, :package, :criteria

    def initialize(provider, package, criteria)
      @provider = provider
      @package = package
      @criteria = criteria
    end

    def install
      @provider.install_package @package
    end

    def installed?
      not @package.installed.nil?
    end
  end

  class Repository
    include Bits::Logging

    def initialize(providers, backend)
      @providers = providers
      @backend = backend
    end

    def find_packages(atom)
      bit = load_bit atom

      packages = []

      bit.provider_ids.each do |provider_id|
        provider = @providers[provider_id]

        criteria = bit.criteria provider_id

        raise "No such provider: #{provider_id}" if provider.nil?

        begin
          package = provider.get_package criteria[:atom]
        rescue MissingPackage
          next
        end

        packages << ProvidedPackage.new(provider, package, criteria)
      end

      packages
    end

    def find_package(atom, criteria={})
      find_packages(atom).each do |package|
        next unless criteria.each.all?{|key, value| package.criteria[key] == value}
        return package
      end

      log.warn "Could not find atom '#{atom}' with criteria #{criteria.inspect}"
      raise MissingProvidedPackage.new atom
    end

    def load_bit(atom)
      path = @backend.fetch(atom)
      Bit.eval path, atom
    end
  end
end
