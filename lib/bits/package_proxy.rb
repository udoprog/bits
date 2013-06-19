module Bits
  # Data class used to keep track of all found ppps (package, provider, params)
  # for a specific bit and the supplied criteria.
  #
  # This allows for eager loading and lazy lookup of if a specific atom can be
  # considered as 'installed' or not.
  class PackageProxy
    attr_accessor :ppps, :criteria

    def initialize(ppps, criteria)
      @ppps = ppps
      @criteria = criteria
    end

    # Check if the following set of parameters matches the specified criteria.
    def matches_criteria?(params)
      criteria.all?{|key, value| value.nil? or params[key] == value}
    end

    def dependencies
      ppps.collect{|ppp| ppp.bit.dependencies}.flatten
    end

    def matching_ppps
      ppps.select do |ppp|
        matches_criteria? ppp.parameters
      end
    end

    # Remove the specified package.
    # The package will be removed from all matching PPPs.
    def remove
      ppps.each do |ppp|
        ppp.provider.remove ppp.package
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

    def providers
      ppps.map do |ppp|
        ppp.provider
      end
    end

    def providers_s
      providers.map(&:provider_id).join ', '
    end
  end
end
