require 'bits/backend'
require 'bits/logging'

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
      log.debug "fetch: #{path}"
      path
    end
  end
end
