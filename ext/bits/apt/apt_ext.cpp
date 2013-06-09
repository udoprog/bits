#include "apt_ext.h"

#include <rice/Module.hpp>

#include <apt-pkg/init.h>

#include "Cache.h"
#include "PackageVersion.h"
#include "Package.h"


extern "C"
void Init_apt_ext()
{
  if (pkgInitConfig(*_config) == false || pkgInitSystem(*_config, _system) == false) {
    return;
  }

  Rice::Module rb_mApt = Rice::define_module("Apt");

  Init_Apt_Cache(rb_mApt);
  Init_Apt_Package(rb_mApt);
  Init_Apt_PackageVersion(rb_mApt);
}
