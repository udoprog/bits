module Bits
  class ProviderException < Exception; end

  class CommandException < Exception; end

  # Is raised when an invalid argument has been passed to a command.
  # This indicates that the help text for this specific command should
  # be shown.
  class InvalidArgument < CommandException; end

  # Is raised when a package being requested does not exist.
  class MissingPackage < ProviderException; end

  # Is raised when a bit does not exist.
  class MissingBit < ProviderException; end

  # Is raised when a package being requested does not exist.
  class MissingProvidedPackage < ProviderException; end
end
