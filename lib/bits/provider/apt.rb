require 'bits/provider'

require 'bits/apt_ext'

module Bits
  class DpkgProvider < Provider
    def self.test
      Apt::Cache::policy("apt-transport-https").each do |p|
        puts p.name, p.current_version
      end
    end
  end
end
