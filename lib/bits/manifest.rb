module Bits
  class Manifest
    class Dependency
      attr_reader :atom, :parameters

      def initialize(atom, parameters)
        @atom = atom
        @parameters = parameters
      end
    end

    attr_reader :depends

    def initialize(root)
      unless root.kind_of? Hash
        raise "Manifest is not of type Hash: #{path}"
      end

      @depends = read_depends root
    end

    private

    def read_depends(root)
      depends = root[:depends]
      return [] if depends.nil?

      unless depends.kind_of? Array
        raise "Expected Array for :depends but got #{depends.inspect}"
      end

      list = Array.new

      depends.each do |spec|
        unless spec.kind_of? Hash
          raise "Expected Hash for dependency spec but got #{spec.inspect}"
        end

        atom = spec[:atom]

        if atom.nil?
          raise "Expected :atom key for dependency"
        end

        list << Bits::Manifest::Dependency.new(atom, spec)
      end

      list
    end
  end
end
