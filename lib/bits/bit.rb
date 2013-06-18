module Bits
  # Class containing data for a single bit.
  class Bit
    attr_accessor :atom, :dependencies

    def initialize(atom, provides, dependencies)
      @atom = atom
      @provides = provides
      @dependencies = dependencies
    end

    def to_s
      "<Bit atom=#{atom} dependencies=#{dependencies.inspect} provides=#{@provides.inspect}>"
    end

    def provided_by?(provider_id)
      @provides.has_key? provider_id
    end

    def get_provides(provider_id)
      unless provided_by? provider_id
        raise "#{self} not provided by #{provider_id}"
      end

      @provides[provider_id]
    end

    def self.eval(reader, atom)
      decl = BitDeclaration.eval reader
      self.new atom, decl.provides, decl.dependencies
    end
  end
end
