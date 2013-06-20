require 'bits/command'
require 'bits/logging'
require 'bits/exceptions'

require 'fileutils'

module Bits
  define_command :query, :desc => "Query for an atom using the specified provider" do
    include Bits::Logging

    def setup(opts)
      opts.banner = "Usage: bits query <provider> <atom>"
    end

    def entry(args)
      if args.size != 2
        raise InvalidArgument.new "Expected two arguments"
      end

      provider_id, atom = args
      provider_id = provider_id.to_sym

      providers = ns[:providers]

      provider = find_provider providers, provider_id

      raise "No such provider: #{provider_id}" if provider.nil?

      puts provider.query(atom)
    end

    def find_provider(providers, provider_id)
      providers.each do |provider|
        return provider if provider.provider_id == provider_id
      end

      nil
    end
  end
end
