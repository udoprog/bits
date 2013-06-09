require 'optparse'

require 'bits/provider/pip'
require 'bits/provider/apt'

module Bits
  def self.parse_options(args)
    params = Hash.new

    opts = OptionParser.new do |options|
      options.banner = 'Usage: bits [options]'
    end

    arguments = opts.parse! args

    return params, arguments
  end

  def self.main(args)
    Provider.providers.each do |p|
      p.test
    end
    params, arguments = parse_options(args).inspect
    return 0
  end
end

if __FILE__ == $0
    exit Bits::main(ARGV)
end
