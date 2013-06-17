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

    BREW = 'apt-get'

    def self.check
      unless HAS_HOMEBREW
        log.debug "homebrew does not seem to be available on this system"
        return false
      end

      true
    end

    def get_package(atom)
      f = Formula.factory(atom)
      return Bits::Package.new(atom, f.installed_version, f.version)
    end

    def install_package(package)
      unless run [BREW, 'install', package.atom]
        raise "Could not install package '#{package.atom}'"
      end
    end

    def remove_package(package)
      unless Bits.spawn [BREW, 'uninstall', package.atom]
        raise "Could not remove package '#{package.atom}'"
      end
    end

    def to_s
      "<HomebrewProvider>"
    end
  end
end
