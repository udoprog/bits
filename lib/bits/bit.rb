module Bits
  # Class containing data for a single bit.
  class Bit
    attr_accessor :atom, :dependencies

    def initialize(atom, provider_data, dependencies)
      @atom = atom
      @provider_data = provider_data
      @dependencies = dependencies
    end

    def to_s
      "<Bit atom=#{atom} dependencies=#{dependencies.inspect} provider_data=#{@provider_data.inspect}>"
    end

    def has_provider?(provider_id)
      @provider_data.has_key? provider_id
    end

    def get_provider_data(provider_id)
      unless has_provider? provider_id
        raise "#{self} not provided by #{provider_id}"
      end

      @provider_data[provider_id]
    end

    def self.eval(reader, atom)
      decl = BitDeclaration.eval reader
      self.new atom, decl.provider_data, decl.dependencies
    end
  end
end
