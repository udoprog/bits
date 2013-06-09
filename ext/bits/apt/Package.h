#ifndef __APT_PACKAGE__H__
#define __APT_PACKAGE__H__

#include <rice/Object.hpp>
#include <rice/Module.hpp>


namespace Apt {
  class Package {
  public:
    Package(std::string name, Rice::Object current_version);
    ~Package();
    std::string name();
    Rice::Object current_version();
    std::string to_s();
  private:
    std::string name_;
    Rice::Object current_version_;
  };
} /* Apt */

extern "C" void Init_Apt_Package(Rice::Module parent);

#endif /* __APT_PACKAGE__H__ */
