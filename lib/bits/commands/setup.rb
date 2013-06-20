require 'bits/command'
require 'bits/logging'
require 'bits/exceptions'

require 'bits/bit_reader/local'
require 'bits/bit'

module Bits
  define_command :setup, :desc => "Setup a local Bits declaration" do
    include Bits::Logging

    def setup(opts)
      ns[:compiled] = nil

      opts.banner = "Usage: bits setup"
      opts.separator ""
      opts.separator "Setup a local Bits declaration"

      opts.on('--[no-]compiled', "Insist on installing an already compiled variant or not") do |v|
        ns[:compiled] = v
      end
    end

    def entry(args)
      repository = ns[:repository]

      criteria = {
        :compiled => ns[:compiled]
      }

      path = File.join Dir.pwd, 'Bits'

      raise "No such file: #{path}" unless File.file? path

      reader = BitReaderLocal.new path

      bit = Bit.eval reader, nil

      bit.dependencies.each do |atom, dependency|
        package = repository.find_package dependency.atom, criteria

        if package.installed?
          log.info "Dependency already installed '#{atom}'"
          next
        end

        log.info "Installing dependency '#{atom}'"

        matching = package.matching_ppps

        raise "No matching PPP could be found" if matching.empty?

        ppp = matching[0]

        provider = ppp.provider
        package = ppp.package

        provider.install package
      end
    end
  end
end
