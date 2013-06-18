module Bits
  # Class containing data for a single bit.
  class Bit
    attr_accessor :atom, :dependencies

    def initialize(atom, provides, dependencies)
      @atom = atom
      @provides = provides
      @dependencies = dependencies
    end

    # List all provider ids that work for this bit.
    def provider_ids
      @provides.keys
    end

    def get_provides(provider_id)
      @provides[provider_id]
    end

    def self.eval(reader, atom)
      decl = BitDeclaration.eval reader
      self.new atom, decl.provides, decl.dependencies
    end
  end
end
