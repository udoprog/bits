#include "Cache.h"

#include <apt-pkg/cachefile.h>
#include <apt-pkg/cacheset.h>

#include "PackageVersion.h"
#include "Package.h"

Rice::Array Apt::Cache::policy(std::string name)
{
  Rice::Array result;

  pkgCacheFile CacheFile;
  pkgCache *Cache = CacheFile.GetPkgCache();
  pkgPolicy *Plcy = CacheFile.GetPolicy();
  pkgSourceList *SrcList = CacheFile.GetSourceList();

  if (Cache == NULL || Plcy == NULL || SrcList == NULL)
  {
    return Qnil;
  }

  APT::CacheSetHelper helper(true, GlobalError::NOTICE);
  APT::PackageList pkgset = APT::PackageList::FromString(CacheFile, name, helper);

  for (APT::PackageList::const_iterator Pkg = pkgset.begin(); Pkg != pkgset.end(); ++Pkg)
  {
    std::string full_name = Pkg.FullName(true);
    Rice::Object current_version;

    if (Pkg->CurrentVer != 0) {
      pkgCache::VerIterator version_iterator = Pkg.CurrentVer();
      std::string version(version_iterator.VerStr());
      std::string arch(version_iterator.Arch());
      std::string section(version_iterator.Section());
      current_version = to_ruby(new PackageVersion(version, arch, section));
    }

    Apt::Package *package = new Apt::Package(full_name, current_version);
    result.push(to_ruby(package));
  }

  return result;
}


extern "C"
void Init_Apt_Cache(Rice::Module parent)
{
  Rice::Module rb_mAptCache = Rice::define_module_under(parent, "Cache")
    .define_singleton_method("policy", &Apt::Cache::policy, Rice::Arg("name"))
  ;
}
