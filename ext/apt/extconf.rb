require 'rubygems'
require 'mkmf-rice'

reqs = []
reqs << have_library('apt-pkg')

if not reqs.all? then
  File.open('Makefile', 'w').write "all:\n\t@echo \"Not building APT extension\""
  exit 0
end

create_makefile 'apt/apt_ext'
