#include "apt_ext.h"

#include <rice/Module.hpp>

#include <apt-pkg/init.h>

#include "Cache.h"
#include "PackageVersion.h"
#include "Package.h"


namespace Apt {
  bool initialize()
  {
    if (!pkgInitConfig(*_config)) {
      return false;
    }

    if (!pkgInitSystem(*_config, _system)) {
      return false;
    }

    return true;
  }
} /* Apt */


extern "C"
void Init_apt_ext()
{
  Rice::Module rb_mApt = Rice::define_module("Apt")
    .define_singleton_method("initialize", &Apt::initialize)
  ;

  Init_Apt_Cache(rb_mApt);
  Init_Apt_Package(rb_mApt);
  Init_Apt_PackageVersion(rb_mApt);
}
