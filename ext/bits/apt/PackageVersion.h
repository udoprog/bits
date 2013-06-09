#ifndef __APT_PACKAGE_VERSION__H__
#define __APT_PACKAGE_VERSION__H__

#include <rice/Module.hpp>

namespace Apt {
  class PackageVersion {
  public:
    PackageVersion(std::string version, std::string arch, std::string section);
    ~PackageVersion();
    std::string version();
    std::string arch();
    std::string section();
    std::string to_s();
  private:
    std::string version_;
    std::string arch_;
    std::string section_;
  };
} /* Apt */

extern "C" void Init_Apt_PackageVersion(Rice::Module parent);

#endif /* __APT_PACKAGE_VERSION__H__ */
