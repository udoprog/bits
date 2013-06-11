module Bits
  # Data class used to keep track of all found ppps (package, provider, params)
  # for a specific bit and the supplied criteria.
  #
  # This allows for eager loading and lazy lookup of if a specific atom can be
  # considered as 'installed' or not.
  class PackageProxy
    attr_accessor :bit, :ppps, :criteria

    def initialize(bit, ppps, criteria)
      @bit = bit
      @ppps = ppps
      @criteria = criteria
    end

    # Check if the following set of parameters matches the specified criteria.
    def matches_criteria?(params)
      criteria.all?{|key, value| params[key] == value}
    end

    def dependencies
      bit.dependencies
    end

    # Install the specified package, this will only install on the first in
    # order provider that matches the specified criteria.
    def install
      ppps.each do |ppp|
        next unless matches_criteria? ppp.params
        ppp.provider.install_package ppp.package
        break
      end
    end

    # Remove the specified package.
    # The package will be removed from all matching PPPs.
    def remove
      ppps.each do |ppp|
        ppp.provider.remove_package ppp.package
      end
    end

    # Determines if the specified package is installed or not.
    def installed?
      ppps.any? do |ppp|
        not ppp.package.installed.nil?
      end
    end

    def installed
      ppps.select do |ppp|
        not ppp.package.installed.nil?
      end
    end
  end
end
