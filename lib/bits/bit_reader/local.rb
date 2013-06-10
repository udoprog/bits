require 'bits/bit_reader'

module Bits
  class BitReaderLocal < BitReader
    def initialize(path)
      @path = path
    end

    def read
      File.new(@path).read
    end
  end
end
