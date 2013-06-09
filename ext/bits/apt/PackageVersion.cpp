#include "PackageVersion.h"

#include <rice/Constructor.hpp>

namespace Apt {
  PackageVersion::PackageVersion(std::string version, std::string arch, std::string section)
    : version_(version)
    , arch_(arch)
    , section_(section)
  {
  }

  PackageVersion::~PackageVersion()
  { }

  std::string PackageVersion::version()
  {
    return version_;
  }

  std::string PackageVersion::arch()
  {
    return arch_;
  }

  std::string PackageVersion::section()
  {
    return section_;
  }

  std::string PackageVersion::to_s() {
    std::stringstream ss;
    ss << "<PackageVersion version=" << version_ << ">";
    return ss.str();
  }
} /* Apt */

extern "C"
void Init_Apt_PackageVersion(Rice::Module parent)
{
  Rice::Class rb_cPackageVersion = 
    Rice::define_class_under<Apt::PackageVersion>(parent, "PackageVersion")
      .define_constructor(Rice::Constructor<Apt::PackageVersion, std::string, std::string, std::string>())
      .define_method("version", &Apt::PackageVersion::version)
      .define_method("arch", &Apt::PackageVersion::arch)
      .define_method("section", &Apt::PackageVersion::section)
      .define_method("to_s", &Apt::PackageVersion::to_s)
  ;
}
