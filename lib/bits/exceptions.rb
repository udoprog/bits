module Bits
  class ProviderException < Exception; end

  # Is raised when a package being requested does not exist.
  class MissingPackage < ProviderException; end

  # Is raised when a bit does not exist.
  class MissingBit < ProviderException; end

  # Is raised when a package being requested does not exist.
  class MissingProvidedPackage < ProviderException; end
end
