module Bits
  class ProviderException < Exception
  end

  # Is raised when a package being requested does not exist.
  class MissingPackage < ProviderException
  end

  # Is raised when a bit does not exist.
  class MissingBit < ProviderException
  end

  # Is raised when a package being requested does not exist.
  class MissingProvidedPackage < ProviderException
  end

  class Provider
    # Specify type name.
    def self.provider_id(value)
      @id = value
    end

    # Specify type documentation.
    def self.provider_doc(value)
      @doc = value
    end

    def self.id
      @id ||= nil
    end

    def self.doc
      @doc ||= nil
    end

    def id
      self.class.id
    end

    def doc
      self.class.doc
    end

    # Override to provide custom static initialization code for provider.
    # Should return true if the specified provider can be used in this system.
    def self.initialize!
      true
    end

    # Return the available providers.
    def self.providers
      @@providers ||= []
    end

    # Add all inheriting classes to a static list of implementors.
    def self.inherited(o)
      providers << o
    end

    def get_package(package)
      raise "not implemented: get_package"
    end
  end
end
