require 'bits/command'
require 'bits/logging'
require 'bits/exceptions'

module Bits
  define_command :show, :desc => "Show a package" do
    include Bits::Logging

    def setup(opts)
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

      criteria = {}
      criteria[:compiled] = ns[:compiled] if ns.has_key? :compiled

      begin
        p = repository.find_package atom, criteria
      rescue MissingBit
        puts "No such atom '#{atom}'"
        return 1
      end

      puts "PPPs:"

      p.ppps.each do |ppp|
        puts "  #{ppp.provider.provider_id}:"
        puts "    Bit: #{ppp.bit.atom}"
        puts "    Package Atom: #{ppp.package.atom}"
        puts "    Installed: #{ppp.package.installed_s}"
        puts "    Candidate: #{ppp.package.candidate_s}"
        puts "    Parameters: #{ppp.parameters}"
      end

      return 0
    end
  end
end
