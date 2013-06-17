module Bits
  class Provider
    class << self
      # Specify type name.
      def provider_id(value)
        @id = value
      end

      # Specify type documentation.
      def provider_doc(value)
        @doc = value
      end

      def id
        @id ||= nil
      end

      def doc
        @doc ||= nil
      end

      # Override to provide custom static initialization code for provider.
      # Should return true if the specified provider can be used in this system.
      def initialize!
        true
      end

      # Return the available providers.
      def providers
        @providers ||= []
      end

      # Add all inheriting classes to a static list of implementors.
      def inherited(o)
        providers << o
      end
    end

    def id
      self.class.id
    end

    def doc
      self.class.doc
    end

    def get_package(package)
      raise "not implemented: get_package"
    end

    def install_package(package)
      raise "not implemented: install_package"
    end

    def remove_package(package)
      raise "not implemented: remove_package"
    end
  end
end
