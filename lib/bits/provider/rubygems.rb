HAS_RUBYGEMS = begin
  require 'rubygems'
  true
rescue LoadError
  false
end

module Bits
  define_provider :rubygems, \
    :desc => "Provides interface for Rubygems" \
  do
    include Bits::Logging
    include Bits::CommandProvider
    include Bits::ProviderReporting

    BREW = 'apt-get'

    def self.check
      unless HAS_RUBYGEMS
        check_error "rubygems is not available on this system"
        return false
      end

      log.debug "rubygems is available"
      true
    end

    def query(atom)
      fetcher = Gem::SpecFetcher.fetcher
      spec_tuples = fetcher.find_matching atom, true, false, false
      puts spec_tuples

      Bits::Package.new(atom, f.installed_version, f.version)
    end

    def install(package)
      execute do
        unless run [BREW, 'install', package.atom]
          raise "Could not install package '#{package.atom}'"
        end
      end
    end

    def remove(package)
      execute do
        unless spawn [BREW, 'uninstall', package.atom]
          raise "Could not remove package '#{package.atom}'"
        end
      end
    end
  end
end
