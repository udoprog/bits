#include "Package.h"
#include "PackageVersion.h"

#include <rice/Class.hpp>
#include <rice/Constructor.hpp>

namespace Apt {
  Package::Package(
    std::string name,
    Rice::Object current_version,
    Rice::Object candidate_version
  )
    : name_(name)
    , current_version_(current_version)
    , candidate_version_(candidate_version)
  {
  }

  Package::~Package()
  { }

  std::string Package::name()
  {
    return name_;
  }

  Rice::Object Package::current_version()
  {
    return current_version_;
  }

  Rice::Object Package::candidate_version()
  {
    return candidate_version_;
  }

  std::string Package::to_s()
  {
    std::stringstream ss;
    ss << "<Package name=" << name_ << ">";
    return ss.str();
  }
} /* Apt */

extern "C"
void Init_Apt_Package(Rice::Module parent)
{
  Rice::Class rb_cPackage = 
    Rice::define_class_under<Apt::Package>(parent, "Package")
      .define_constructor(Rice::Constructor<Apt::Package, std::string, Rice::Object>())
      .define_method("name", &Apt::Package::name)
      .define_method("current_version", &Apt::Package::current_version)
      .define_method("to_s", &Apt::Package::to_s)
  ;
}
