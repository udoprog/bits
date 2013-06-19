module Bits
  class BitReference
    attr_reader :atom

    def initialize(atom)
      @atom = atom
    end
  end

  class BitParameters
    attr_reader :parameters

    def initialize(parameters)
      @parameters = parameters
    end
  end

  # Class used to manage state of a bit declaration file.
  class BitDeclaration
    attr_accessor :provider_data, :dependencies

    def initialize
      @provider_data = {}
      @dependencies = {}
    end

    # Used inside bit declaration.
    def provided_by(provider_id, params={})
      @provider_data[provider_id] = BitParameters.new params
    end

    # Used inside bit declaration.
    # Defines that the following set of providers are provided by another bit.
    def provided_for(params={})
      params.each do |key, value|
        key = key.to_sym
        @provider_data[key] = BitReference.new value
      end
    end

    def depends(atom, params={})
      @dependencies[atom] = params
    end

    def self.eval(reader)
      decl = self.new
      decl.instance_eval reader.read
      decl
    end
  end

end
