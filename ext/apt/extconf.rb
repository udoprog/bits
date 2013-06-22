require 'rubygems'
require 'mkmf-rice'

reqs = []
reqs << have_library('apt-pkg')

unless reqs.all? then
  File.open 'Makefile', 'w' do |f|
    f.write "all:\n"
    f.write "%:\n"
    f.write "\t@echo \"$@: Not building APT extension\"\n"
  end

  exit 0
end

create_makefile 'apt/apt_ext'
