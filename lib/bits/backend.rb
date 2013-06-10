module Bits
  class Backend
    # Get a bit corresponding to the specified atom and return BitReader that
    # can read the contents of it.
    def fetch(atom)
      raise "not implemented: fetch"
    end
  end
end
