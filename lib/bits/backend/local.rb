require 'bits/backend'
require 'bits/logging'

require 'bits/bit_reader/local'

module Bits
  class LocalBackend < Backend
    include Bits::Logging

    def initialize(path)
      @path = path
    end

    # no need to fetch
    def fetch(atom)
      path = File.join @path, "#{atom}.bit"
      raise MissingBit.new atom unless File.file? path
      log.debug "bit from local path: #{path}"
      BitReaderLocal.new path
    end
  end
end
