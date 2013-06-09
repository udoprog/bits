require 'bits/provider'

module Bits
  class PipProvider < Provider
    provider_id :pip
    provider_doc "Provides interface for Python pip"

    def get_version(package)
      nil
    end
  end
end
