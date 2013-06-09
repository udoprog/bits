# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bits/version'

Gem::Specification.new do |spec|
  spec.name = "bits"
  spec.version = Bits::VERSION
  spec.authors = ["John-John Tedro"]
  spec.email = ["johnjohn.tedro@gmail.com"]
  spec.description = %q{Meta package manager}
  spec.summary = %q{Meta package manager}
  spec.homepage = ""
  spec.license = "GPLv3"

  spec.files = Dir.glob('bin/*') +
               Dir.glob('lib/**/*.rb') +
               Dir.glob('ext/**/*/*.{cpp,h,rb}')

  spec.executables = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files = spec.files.grep(%r{^(test|spec|features)/})

  spec.require_paths = ["lib"]

  spec.extensions = [
    'ext/bits/apt/extconf.rb'
  ]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
