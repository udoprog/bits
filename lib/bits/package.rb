module Bits
  class Package
    attr_reader :name, :installed_version, :candidate_version

    def initialize(name, installed_version, candidate_version)
      @name = name
      @installed_version = installed_version
      @candidate_version = candidate_version
    end
  end
end
