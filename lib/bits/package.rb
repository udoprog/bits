module Bits
  class Package
    attr_reader :atom, :installed, :candidate

    def initialize(atom, installed, candidate)
      @atom = atom
      @installed = installed
      @candidate = candidate
    end

    def to_s
      installed_s = @installed || "(not installed)"
      candidate_s = @candidate || "(no candidate)"
      "<Package atom='#{@atom}' installed='#{installed_s}' candidate='#{candidate_s}'>"
    end
  end
end
