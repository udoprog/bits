require 'mkmf-rice'

have_library 'apt-pkg'

create_makefile 'bits/apt/apt_ext'
