require 'bits/command'
require 'bits/logging'
require 'bits/exceptions'

require 'fileutils'

module Bits
  define_command :sync, :desc => "sync local repository" do
    include Bits::Logging

    GIT = 'git'
    CLONE_URL = 'https://github.com/udoprog/bits-repo'

    def setup(opts)
      opts.banner = "Usage: bits sync"
      opts.separator ""
      opts.separator "Sync local repository"
    end

    def entry(args)
      dir = ns[:local_repository_dir]

      setup_original dir unless File.directory? dir

      Dir.chdir(dir) do
        Bits.spawn [GIT, 'pull', 'origin', 'master']
      end
    end

    def setup_original(dir)
      Bits.spawn [GIT, 'clone', CLONE_URL, dir]
    end
  end
end
