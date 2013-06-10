require 'optparse'

require 'bits/provider/pip'
require 'bits/provider/apt'
require 'bits/package'
require 'bits/repository'

module Bits
  def self.parse_options(args)
    params = Hash.new

    opts = OptionParser.new do |options|
      options.banner = 'Usage: bits [options]'
    end

    arguments = opts.parse! args

    return params, arguments
  end

  def self.setup_logging
    log = Log4r::Logger.new 'Bits'
    log.outputters << Log4r::Outputter.stdout
    log.level =  Log4r::DEBUG
    log
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
    @log = setup_logging

    providers = setup_providers

    params, arguments = parse_options(args).inspect

    repository = Bits::Repository.new providers, './repo'

    p = repository.find_package 'python-setuptools', :compiled => false

    puts "#{p.provider.id}: #{p.package} #{p.provider} #{p.params.inspect}"

    return 0
  end
end

if __FILE__ == $0
    exit Bits::main(ARGV)
end
