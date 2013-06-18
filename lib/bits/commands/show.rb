require 'bits/command'
require 'bits/logging'
require 'bits/exceptions'

module Bits
  define_command :show, :desc => "Show a package" do
    include Bits::Logging

    def self.setup(opts)
      opts.banner = "Usage: bits show <bit>"
      opts.separator ""
      opts.separator "Show information about the specified bit."
    end

    def entry(args)
      if args.empty? then
        puts parser.help
        return 1
      end

      atom = args[0]

      repository = ns[:repository]

      params = {}
      params[:compiled] = ns[:compiled] if ns.has_key? :compiled

      begin
        p = repository.find_package atom, params
      rescue MissingBit
        puts "No such atom '#{atom}'"
        return 1
      end

      puts "PPPs:"

      p.ppps.each do |ppp|
        puts "  #{ppp.provider.id}:"
        puts "    Atom: #{ppp.bit.atom}"
        puts "    Package: #{ppp.package}"
        puts "    Params: #{ppp.params.inspect}"
      end

      return 0
    end
  end
end
