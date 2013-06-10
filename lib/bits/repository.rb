require 'bits/logging'

module Bits
  # Class used to manage state of a bit declaration file.
  class BitDeclaration
    def initialize
      @provider_params = {}
    end

    # Used inside bit declaration.
    def provide(provider_id, params={})
      @provider_params[provider_id] = params
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

    def params(provider_id)
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
    def initialize(packages, criteria)
      @packages = packages
      @criteria = criteria
    end

    def matches_criteria?(params)
      @criteria.all?{|key, value| params[key] == value}
    end

    def install
      @packages.each do |provider, package, params|
        next unless matches_criteria? params
        provider.install_package package
        break
      end
    end

    def remove
      @packages.each do |provider, package, params|
        provider.remove_package package
      end
    end

    def installed?
      @packages.any?{|provider, package, params|
        not package.installed.nil?
      }
    end

    def installed
      @packages.select{|provider, package, params|
        not package.installed.nil?
      }
    end
  end

  class Repository
    include Bits::Logging

    def initialize(providers, backend)
      @providers = providers
      @backend = backend
    end

    def get_provider(provider_id)
      @providers[provider_id]
    end

    def iterate_packages(atom)
      bit = load_bit atom

      bit.provider_ids.each do |provider_id|
        provider = get_provider provider_id

        if provider.nil? then
          log.debug "No such provider: #{provider_id}"
          next
        end

        params = bit.params provider_id

        yield [provider, params]
      end
    end

    def find_package(atom, criteria={})
      all_packages = []
      match = nil

      iterate_packages(atom) do |provider, params|
        begin
          package = provider.get_package(params[:atom])
        rescue MissingPackage
          next
        end

        all_packages << [provider, package, params]

        next unless match.nil?
      end

      if all_packages.empty?
        log.warn "Could not find atom '#{atom}' with criteria #{criteria.inspect}"
        raise MissingProvidedPackage.new atom
      end

      return ProvidedPackage.new all_packages, criteria
    end

    def load_bit(atom)
      path = @backend.fetch(atom)
      Bit.eval path, atom
    end
  end
end
