require 'bits/command'
require 'bits/logging'

module Bits
  class ShowCommand < Command
    include Bits::Logging

    command_name :show

    def initialize(ns)
      @ns = ns
    end

    def parser
      @parser ||= OptionParser.new do |opts|
        opts.banner = "Usage: bits show <bit>"
        opts.separator ""
        opts.separator "Show information about the specified bit."
      end
    end

    def run(args)
      if args.empty? then
        puts parser.help
        return 1
      end

      atom = args[0]

      repository = @ns[:repository]

      params = {}
      params[:compiled] = @ns[:compiled] if @ns.has_key? :compiled

      begin
        p = repository.find_package atom, params
      rescue MissingBit
        puts "No such atom '#{atom}'"
        return 1
      end

      puts "Atom: #{p.bit.atom}"
      puts "PPPs:"

      p.ppps.each do |ppp|
        puts "  #{ppp.provider.id}:"
        puts "    Package: #{ppp.package}"
        puts "    Params: #{ppp.params}"
      end

      return 0
    end
  end
end
