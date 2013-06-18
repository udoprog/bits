module Bits
  # Class used to manage state of a bit declaration file.
  class BitDeclaration
    attr_accessor :provides, :dependencies

    def initialize
      @provides = {}
      @dependencies = {}
    end

    # Used inside bit declaration.
    def provided_by(provider_id, params={})
      @provides[provider_id] = params
    end

    # Used inside bit declaration.
    # Defines that the following set of providers are provided by another bit.
    def provided_for(params={})
      params.each do |key, value|
        key = key.to_sym
        @provides[key] = value
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
