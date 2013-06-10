module Bits
  class Package
    attr_reader :atom, :installed, :candidate

    def initialize(atom, installed, candidate)
      @atom = atom
      @installed = installed
      @candidate = candidate
    end

    def to_s
      "<Package atom=#{@atom} installed=#{@installed} candidate=#{@candidate}>"
    end
  end
end
