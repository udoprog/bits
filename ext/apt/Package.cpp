#include "Package.h"
#include "PackageVersion.h"

#include <rice/Class.hpp>
#include <rice/Constructor.hpp>

namespace Apt {
  Package::Package(
    std::string name,
    Rice::Object current,
    Rice::Object candidate
  )
    : name_(name)
    , current_(current)
    , candidate_(candidate)
  {
  }

  Package::~Package()
  { }

  std::string Package::name()
  {
    return name_;
  }

  Rice::Object Package::current()
  {
    return current_;
  }

  Rice::Object Package::candidate()
  {
    return candidate_;
  }

  std::string Package::to_s()
  {
    std::stringstream ss;

    ss << "<Package"
       << " name=" << name_
       << " current=" << current_
       << " candidate=" << candidate_
       << ">";

    return ss.str();
  }
} /* Apt */

extern "C"
void Init_Apt_Package(Rice::Module parent)
{
  Rice::Class rb_cPackage = 
    Rice::define_class_under<Apt::Package>(parent, "Package")
      .define_constructor(Rice::Constructor<Apt::Package, std::string, Rice::Object, Rice::Object>())
      .define_method("name", &Apt::Package::name)
      .define_method("current", &Apt::Package::current)
      .define_method("candidate", &Apt::Package::candidate)
      .define_method("current", &Apt::Package::current)
      .define_method("to_s", &Apt::Package::to_s)
  ;
}
