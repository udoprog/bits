require 'bits/command'
require 'bits/logging'
require 'bits/installer_mixin'
require 'bits/manifest'
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

      manifest = File.open(path) do |f|
        Bits::Manifest.new YAML.load(f)
      end

      criteria = {
        :compiled => ns[:compiled]
      }

      log.info "Running manifest: #{path}"

      begin
        packages = resolve_dependencies manifest, criteria
      rescue Bits::MissingDependencies => e
        puts "Missing Dependencies:"

        e.missing.each do |dep|
          puts "  - #{dep.atom}"
        end

        return 1
      end

      packages.each do |package|
        install_package package, force=ns[:force]
      end

      return 0
    end

    private

  end
end
