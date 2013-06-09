# Bits

Bits is a meta package manager.
It will maintain relationship between packages from various package managers.

## Installation

Add this line to your application's Gemfile:

    gem 'bits'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install bits

## Usage

This will work by specifying package manager neutral manifests for each package
on each provided platform (pip, gem, apt, yum, portage).

  # package atom
  package 'ruby-json'
  # package requires compilation.
  native true

  provide :apt,
    :package_name => 'ruby-json',

  provide :gem,
    :package_name => 'json',
    :compiled => false

This will allow the ruby-json package from being installed either using gem, or
using apt depending on what the situation requires.

Bits will then hook into all required package managers available in order to
satisfy any specified dependency.

These manifests will be hosted and maintained centrally.

More information coming soon.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
