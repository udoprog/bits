module Bits
  class ProviderException < Exception; end

  class CommandException < Exception; end

  # Is raised when an invalid argument has been passed to a command.
  # This indicates that the help text for this specific command should
  # be shown.
  class InvalidArgument < CommandException; end

  # Indicate that some dependencies are missing
  class MissingDependencies < CommandException
    attr_reader :missing

    def initialize(missing)
      @missing = missing
      super "Missing dependencies: #{missing_s}"
    end

    def missing_s
      @missing.join ', '
    end
  end

  # Is raised when a package being requested does not exist.
  class MissingPackage < ProviderException; end

  # Is raised when a bit does not exist.
  class MissingBit < ProviderException; end

  # Is raised when a package being requested does not exist.
  class MissingProvidedPackage < ProviderException; end

  # Is raised when a spawn command fails early.
  class SpawnException < Exception
    attr_reader :errno

    def initialize(message, errno=0)
      super message
      @errno = errno
    end
  end

  # Is raised when commlunicating with an interface fails.
  class InterfaceException < Exception; end
end
