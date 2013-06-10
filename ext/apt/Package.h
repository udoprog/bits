#ifndef __APT_PACKAGE__H__
#define __APT_PACKAGE__H__

#include <rice/Object.hpp>
#include <rice/Module.hpp>


namespace Apt {
  class Package {
  public:
    Package(
      std::string name,
      Rice::Object current,
      Rice::Object candidate
    );
    ~Package();
    std::string name();
    Rice::Object current();
    Rice::Object candidate();
    std::string to_s();
  private:
    std::string name_;
    Rice::Object current_;
    Rice::Object candidate_;
  };
} /* Apt */

extern "C" void Init_Apt_Package(Rice::Module parent);

#endif /* __APT_PACKAGE__H__ */
