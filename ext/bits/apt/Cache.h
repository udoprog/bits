#ifndef __APT_CACHE__H__
#define __APT_CACHE__H__

#include <rice/Module.hpp>
#include <rice/Array.hpp>

namespace Apt {
  namespace Cache {
    /**
     * Interface similar to apt-cache policy.
     */
    Rice::Array policy(std::string name);
  } /* Cache */
} /* Apt */

extern "C" void Init_Apt_Cache(Rice::Module parent);

#endif /* __APT_CACHE__H__ */
