module Bits
  # Class used to manage state of a bit declaration file.
  class BitDeclaration
    attr_accessor :provide_params, :dependencies

    def initialize
      @provide_params = {}
      @dependencies = {}
    end

    # Used inside bit declaration.
    def provide(provider_id, params={})
      @provide_params[provider_id] = params
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
