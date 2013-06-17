require 'bits/backend'
require 'bits/logging'
require 'bits/exceptions'

module Bits
  class JoinBackend < Backend
    include Bits::Logging

    def initialize(backends)
      @backends = backends
    end

    # no need to fetch
    def fetch(atom)
      @backends.each do |backend|
        begin
          return backend.fetch atom
        rescue MissingBit
          next
        end
      end

      raise MissingBit.new atom
    end
  end
end
