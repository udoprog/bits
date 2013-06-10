module Bits
  # Class containing data for a single bit.
  class Bit
    attr_accessor :atom

    def initialize(atom, provide_params, dependencies)
      @atom = atom
      @provide_params = provide_params
      @dependencies = dependencies
    end

    # List all provider ids that work for this bit.
    def provider_ids
      @provide_params.keys
    end

    def get_params(provider_id)
      p = @provide_params[provider_id]

      return nil if p.nil?

      {
        :atom => (p[:atom] || @atom),
        :compiled => (p[:compiled] || false),
      }
    end

    def self.eval(reader, atom)
      decl = BitDeclaration.eval reader
      self.new atom, decl.provide_params, decl.dependencies
    end
  end
end
