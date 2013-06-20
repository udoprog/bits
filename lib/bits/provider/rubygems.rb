module Bits
  define_provider :rubygems, \
    :desc => "Provides interface for Rubygems" \
  do
    include Bits::Logging
    include Bits::CommandProvider
    include Bits::ExternalInterface
    include Bits::ProviderReporting

    GEM = 'gem'

    def self.check
      unless self.setup_interface :ruby, :capabilities => [:rubygems]
        check_error "Could not setup required interface"
        return false
      end

      log.debug "rubygems is available"
      true
    end

    def initialize(ns)
      super ns
      @client = interfaces[:ruby]
    end

    def query(atom)
      type, info = @client.request :rubygems_info, :package => atom
      raise MissingPackage.new atom if type == :missing_package
      raise "Expected info response but got: #{type}" unless type == :info
      installed = info['installed']
      candidate = info['candidate']
      Bits::Package.new(atom, installed, candidate)
    end

    def install(package)
      execute do
        unless run [GEM, 'install', package.atom]
          raise "Could not install package '#{package.atom}'"
        end
      end
    end

    def remove(package)
      execute do
        unless spawn [GEM, 'uninstall', package.atom]
          raise "Could not remove package '#{package.atom}'"
        end
      end
    end
  end
end
