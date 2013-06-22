require 'bits/command'
require 'bits/logging'
require 'bits/exceptions'

require 'fileutils'

module Bits
  define_command :sync, \
    :desc => "sync local repository" \
  do
    include Bits::Logging

    GIT = 'git'
    CLONE_URL = 'https://github.com/udoprog/bits-repo'

    def setup(opts)
      opts.banner = "Usage: bits #{switch}"
      opts.separator ""
      opts.separator "Sync local repository"
    end

    def entry(args)
      repo_dir = ns[:repo_dir]
      providers = ns[:providers]

      clone repo_dir unless File.directory? repo_dir

      log.info "Syncing bits"

      Dir.chdir(repo_dir) do
        Bits.spawn [GIT, 'pull', 'origin', 'master']
      end

      providers.each do |provider|
        log.info "Syncing provider: #{provider.to_s}"
        provider.sync
      end
    end

    def clone(repo_dir)
      Bits.spawn [GIT, 'clone', CLONE_URL, repo_dir]
    end
  end
end
