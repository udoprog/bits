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

  # Initialize all available providers and return an array containing an
  # instance of them.
  def self.setup_providers
    providers = Hash.new

    Provider.providers.each do |p|
      next unless p.initialize!
      providers[p.id] = p.new
    end

    return providers
  end

  def self.main(args)
    providers = setup_providers

    params, arguments = parse_options(args).inspect

    package_name = 'python-setuptools'

    providers.each do |id, p|
      package = p.get_installed package_name

      unless package
        puts "#{p.id}: Package not available '#{package_name}'"
        next
      end

      unless package
        puts "#{p.id}: Package not installed '#{package.name}'"
        next
      end

      puts "#{p.id}: #{package.name} = #{package.version}"
    end

    return 0
  end
end

if __FILE__ == $0
    exit Bits::main(ARGV)
end
