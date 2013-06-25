require 'bits/provider'
require 'bits/provider_reporting'
require 'bits/command_provider'
require 'bits/spawn'
require 'bits/package'
require 'bits/logging'
require 'bits/exceptions'
require 'bits/cache'

require 'bits/external_interface'

require "xmlrpc/client"

module Bits
  define_provider :python,
    :desc => "Provider for Python Packaging" \
  do
    include Bits::Logging
    include Bits::CommandProvider
    include Bits::ExternalInterface
    include Bits::ProviderReporting
    include Bits::Cache

    PIP = 'pip'
    INDEX = 'https://pypi.python.org/pypi'

    def self.check
      unless self.check_command [PIP, '--version'], 'PIP'
        check_error "Could not execute '#{PIP} --version'"
        return false
      end

      unless self.setup_interface :python, :capabilities => [:pkg_resources]
        check_error "Could not setup require python interface"
        return false
      end

      log.debug "python extensions is available"
      true
    end

    def setup
      @client = XMLRPC::Client.new_from_uri(INDEX)
      @client.http_header_extra = {'Content-Type' => 'text/xml'}
      @python = self.class.interfaces[:python]
      @cache = setup_cache ns[:bits_dir], provider_id
    end

    def sync
      # TODO: currently fetching the candidate version is a very slow operation
      # sinc the initial list of packages does not include it. This needs to
      # be mitigated somehow.

      log.warn "Syncing without candidate version information"

      t = Time.new

      sync_file = File.join ns[:bits_dir], "#{provider_id}.sync"

      last_sync = get_last_sync sync_file

      if last_sync.nil?
        content = read_full
      else
        content = read_partial last_sync
      end

      File.open(sync_file, 'w') do |f|
        f.puts t.to_i.to_s
      end

      @cache.set content
      @cache.save
    end

    def query(package_atom)
      candidate = @cache[package_atom]

      candidate_version = if candidate.nil?
        get_candidate_version package_atom
      else
        candidate['version']
      end

      raise MissingPackage.new package_atom if candidate_version.nil?

      current = get_installed_version package_atom

      Bits::Package.new package_atom, current, candidate_version
    end

    def install(package)
      execute do
        unless run [PIP, 'install', package.atom], :superuser => true
          raise "Could not install package '#{package.atom}'"
        end
      end
    end

    def remove(package)
      execute do
        unless run [PIP, 'uninstall', package.atom], :superuser => true
          raise "Could not remove package '#{package.atom}'"
        end
      end
    end

    private

    def get_installed_version(package_atom)
      type, response = @python.request :python_info, :atom => package_atom
      return nil if type == :missing_atom
      response['installed']
    end

    def get_candidate_version(package_atom)
      begin
        result = @client.call(:package_releases, package_atom)
      rescue SocketError
        return nil
      end

      return nil if result.empty?
      return result[0]
    end

    # get the number from the specified file when we where last synced to
    # upstream repository.
    def get_last_sync(sync_file)
      if File.file? sync_file
        File.new(sync_file).read.to_i
      else
        nil
      end
    end

    def read_partial(last_sync)
      result = @client.call :changelog, last_sync

      log.info "PARTIAL: Syncing #{result.size} python packages"

      releases = Hash.new

      result.each do |name, version, timestamp, purpose|
        next if purpose != 'new release'

        releases[name] = {
          'atom' => name,
          'version' => version,
        }
      end

      releases
    end

    def read_full
      remote_packages = @client.call :list_packages

      log.info "FULL: Syncing #{remote_packages.size} python packages"

      packages = Hash.new

      remote_packages.each do |name|
        # TODO: currently syncing candidate version is very slow. This needs
        # to be mitigated.

        #candidate = get_candidate_version name
        candidate = "0.0.0"

        next if candidate.nil?

        packages[name] = {
          'atom' => name,
          'version' => candidate,
        }
      end

      packages
    end
  end
end
