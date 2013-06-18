$old = Array.new $:

HAS_HOMEBREW = begin
  $: << '/usr/local/Library/Homebrew'
  require 'global'
  require 'formula'
  true
rescue LoadError
  $:.replace $old
  false
end

module Bits
  define_provider :homebrew, \
    :desc => "Provides interface for Homebrew" \
  do
    include Bits::Logging
    include Bits::CommandProvider
    include Bits::ProviderReporting

    BREW = 'apt-get'

    def self.check
      unless HAS_HOMEBREW
        check_error "homebrew is not available on this system"
        return false
      end

      log.debug "homebrew is available"
      true
    end

    def get_package(atom)
      begin
        f = Formula.factory(atom)
      rescue FormulaUnavailableError
        raise MissingPackage.new(atom)
      end

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

    def to_s
      "<HomebrewProvider>"
    end
  end
end
