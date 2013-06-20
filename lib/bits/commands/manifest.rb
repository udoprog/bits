require 'bits/command'
require 'bits/logging'
require 'bits/installer_mixin'
require 'yaml'

module Bits
  define_command :manifest, :desc => 'Run a manifest (this is the default action)' do
    include Bits::Logging
    include Bits::InstallerMixin

    BITS_MANIFEST = "Bits"

    def setup(opts)
      ns[:compiled] = nil

      opts.banner = "Usage: bits manifest [path]"

      setup_installer_opts opts
    end

    def entry(args)
      if args.empty? then
        path = File.join Dir.pwd, BITS_MANIFEST
      else
        path = args.first
      end

      raise "No manifest in path: #{path}" unless File.file? path

      manifest = YAML.load File.new(path)

      depends = manifest[:depends]

      criteria = {
        :compiled => ns[:compiled]
      }

      repository = ns[:repository]

      unless depends.nil?
        unless depends.kind_of? Array
          raise ":depends should be a List"
        end

        depends.each do |atom|
          package = repository.find_package atom, criteria
          install_package package, force=ns[:force]
        end
      end
    end
  end
end
