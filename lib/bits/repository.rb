module Bits
  # Class used to manage state of a bit declaration file.
  class BitDeclaration
    def initialize
      @package = nil
      @provider_params = {}
    end

    def package(package)
      @package = package
    end

    # Used inside bit declaration.
    def provide(provider_id, params={})
      @provider_params[provider_id] = params
    end

    def get_package
      @package
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
      raise "'package' declaration must be specified" if decl.get_package.nil?
      decl
    end
  end

  # Class used to manage a single bit.
  class Bit
    attr_accessor :package, :path

    def initialize(package, provider_params)
      @package = package
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
        :atom => (p[:atom] || @package),
        :compiled => (p[:compiled] || false),
      }
    end

    def self.eval(path)
      decl = BitDeclaration.eval path
      self.new decl.get_package, decl.get_provider_params
    end
  end

  class ProvidedPackage
    attr_accessor :provider, :package, :params

    def initialize(provider, package, params)
      @provider = provider
      @package = package
      @params = params
    end
  end

  class Repository
    def initialize(providers, path)
      @providers = providers
      @bits = {}

      iterate_repository(path) do |bit|
        @bits[bit.package] = bit
      end
    end

    def find_packages(atom)
      bit = @bits[atom]

      raise MissingBit.new atom if bit.nil?

      packages = []

      bit.provider_ids.each do |provider_id|
        provider = @providers[provider_id]

        params = bit.params provider_id

        raise "No such provider: #{provider_id}" if provider.nil?

        begin
          package = provider.get_package params[:atom]
        rescue MissingPackage
          next
        end

        packages << ProvidedPackage.new(provider, package, params)
      end

      packages
    end

    def find_package(atom, params={})
      find_packages(atom).each do |package|
        next unless params.each.all?{|key, value| package.params[key] == value}
        return package
      end

      raise MissingProvidedPackage.new atom
    end

    def iterate_repository(path)
      return unless block_given?

      Dir.foreach(path) do |name|
        next if name.start_with?('.')
        next unless name.end_with?('.bit')

        bit = Bit.eval File.join(path, name)

        yield bit
      end
    end
  end
end
