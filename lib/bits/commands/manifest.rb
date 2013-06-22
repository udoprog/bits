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

      unless manifest.kind_of? Hash
        raise "Manifest is not of type Hash: #{path}"
      end

      depends = manifest[:depends]

      criteria = {
        :compiled => ns[:compiled]
      }

      log.info "Running manifest: #{path}"

      unless depends.nil?
        begin
          packages = resolve_packages depends, criteria
        rescue Bits::MissingDependencies => e
          puts "Missing Dependencies:"

          e.missing.each do |m|
            puts "  - #{m}"
          end

          return 1
        end

        packages.each do |package|
          install_package package, force=ns[:force]
        end
      else
        log.info "No dependencies specified"
      end

      return 0
    end

    private

  end
end
