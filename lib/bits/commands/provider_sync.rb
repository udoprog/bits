require 'bits/command'
require 'bits/logging'
require 'bits/exceptions'

module Bits
  define_command :provider_sync, \
    :switch => 'provider-sync', \
    :desc => "Sync the specified provider" \
  do
    include Bits::Logging

    def setup(opts)
      opts.banner = "Usage: bits #{switch} <provider>"
      opts.separator ""
      opts.separator "Providers:"

      ns[:providers].each do |provider|
        opts.separator "  #{provider.provider_id}"
      end
    end

    def entry(args)
      if args.size != 1
        raise InvalidArgument.new "Expected a single argument"
      end

      provider_id = args.first
      provider_id = provider_id.to_sym

      providers = ns[:providers]

      provider = find_provider providers, provider_id

      raise "No such provider: #{provider_id}" if provider.nil?

      log.info "Syncing provider: #{provider_id}"

      provider.sync
    end

    def find_provider(providers, provider_id)
      providers.each do |provider|
        return provider if provider.provider_id == provider_id
      end

      nil
    end
  end
end
