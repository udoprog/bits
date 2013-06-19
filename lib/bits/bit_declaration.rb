require 'yaml'

module Bits
  class BitReference
    attr_reader :atom

    def initialize(atom)
      @atom = atom
    end

    def to_s
      "<BitReference #{@atom}>"
    end
  end

  class BitParameters
    attr_reader :parameters

    def initialize(parameters)
      @parameters = parameters
    end

    def to_s
      "<BitParameters #{@parameters}>"
    end
  end

  # Class used to manage state of a bit declaration file.
  class BitDeclaration
    attr_accessor :provider_data, :dependencies

    def initialize(data)
      @provider_data = parse_provider_data data
      @dependencies = parse_dependencies data
    end

    def parse_provider_data(data)
      h = Hash.new

      provided_for = data[:provided_for]
      provided_by = data[:provided_by]

      unless provided_by.nil?
        unless provided_by.kind_of? Hash
          raise "Expected Hash but got '#{provided_by.inspect}'"
        end

        provided_by.each do |provider_id, parameters|
          unless parameters.kind_of? Hash
            raise "Expected Hash but got '#{parameters.inspect}'"
          end

          unless provider_id.kind_of? Symbol
            raise "Expected Symbol but got '#{provider_id.inspect}'"
          end

          unless h[provider_id].nil?
            raise "Provider already defined '#{provider_id}'"
          end

          h[provider_id] = BitParameters.new parameters
        end
      end

      unless provided_for.nil?
        unless provided_for.kind_of? Hash
          raise "Expected Hash but got '#{provided_for.inspect}'"
        end

        provided_for.each do |provider_id, reference|
          unless reference.kind_of? String
            raise "Expected String but got '#{reference.inspect}'"
          end

          unless provider_id.kind_of? Symbol
            raise "Expected Symbol but got '#{provider_id.inspect}'"
          end

          unless h[provider_id].nil?
            raise "Provider already defined '#{provider_id}'"
          end

          h[provider_id] = BitReference.new reference
        end
      end

      h
    end

    def parse_dependencies(data)
      h = Hash.new

      depends = data[:depends]

      unless depends.nil?
        unless depends.kind_of? Array
          raise "Expected Array but got '#{depends.inspect}'"
        end

        depends.each do |item|
          unless item.kind_of? Hash
            raise "Expected Hash but got '#{item.inspect}'"
          end

          atom = item[:atom]

          if atom.nil?
            raise "Expected :atom to be not null in dependency"
          end

          h[atom] = BitParameters.new item
        end
      end

      h
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
      data = YAML.load reader.read
      decl = self.new data
      decl
    end
  end

end
