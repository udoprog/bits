module Bits
  # Data class used to keep track of all found packages for a specific bit and
  # the supplied criteria.
  #
  # This allows for eager loading and lazy lookup of if a specific atom can be
  # considered as 'installed' or not.
  class PackageProxy
    attr_accessor :bit, :packages, :criteria

    def initialize(bit, packages, criteria)
      @bit = bit
      @packages = packages
      @criteria = criteria
    end

    # Check if the following set of parameters matches the specified criteria.
    def matches_criteria?(params)
      criteria.all?{|key, value| params[key] == value}
    end

    # Install the specified package, this will only install on the first in
    # order provider that matches the specified criteria.
    def install
      packages.each do |provider, package, params|
        next unless matches_criteria? params
        provider.install_package package
        break
      end
    end

    # Remove the specified package.
    def remove
      packages.each do |provider, package, params|
        provider.remove_package package
      end
    end

    # Determines if the specified package is installed or not.
    def installed?
      packages.any?{|provider, package, params|
        not package.installed.nil?
      }
    end

    def installed
      packages.select{|provider, package, params|
        not package.installed.nil?
      }
    end
  end
end
