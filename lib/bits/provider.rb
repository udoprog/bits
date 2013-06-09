module Bits
  class Provider
    def self.providers
      @@providers ||= []
    end

    def self.inherited(o)
      providers << o
    end
  end
end
