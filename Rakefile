require "bundler/gem_tasks"

require 'rake/clean'
require 'rspec/core/rake_task'

NAME = 'bits'

EXTENSIONS = Dir.glob("ext/#{NAME}/*").select{|p| File.directory? p}

EXTENSIONS.each do |path|
  name = File.basename(path)
  ext_path = String.new(path)
  path.slice! 0, 4
  target = "lib/#{path}/#{name}_ext.so"
  target_dir = File.dirname(target)

  dependencies = Dir.glob("#{ext_path}/*.{cpp,h}")

  # rule to build the extension: this says
  # that the extension should be rebuilt
  # after any change to the files in ext
  file target => dependencies do
    Dir.chdir(ext_path) do
      # this does essentially the same thing
      # as what RubyGems does
      ruby "extconf.rb"
      sh "make"
    end

    mkdir target_dir
    cp File.join(ext_path, "#{name}_ext.so"), target
  end

  task :spec => target
end

# use 'rake clean' and 'rake clobber' to
# easily delete generated files
CLEAN.include('ext/**/*{.o,.log,.so}')
CLEAN.include('ext/**/Makefile')

CLOBBER.include('lib/**/*.so')

RSpec::Core::RakeTask.new(:spec)
task :default => :spec
