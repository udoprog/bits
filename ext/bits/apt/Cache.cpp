#include "Cache.h"

#include <apt-pkg/cachefile.h>
#include <apt-pkg/cacheset.h>

#include "PackageVersion.h"
#include "Package.h"

PackageVersion *to_package_version(pkgCache::VerIterator iterator)
{
  std::string version(iterator.VerStr());
  std::string arch(iterator.Arch());
  std::string section(iterator.Section());
  return new PackageVersion(version, arch, section);
}

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
    Rice::Object candidate_version;

    if (Pkg->CurrentVer != 0) {
      pkgCache::VerIterator current = Pkg.CurrentVer();
      current_version = to_ruby(to_package_version(current));
    }

    pkgCache::VerIterator candidate = Plcy->GetCandidateVer(Pkg);

    if (candidate.end() != true) {
      candidate_version = to_ruby(to_package_version(candidate));
    }

    Apt::Package *package = new Apt::Package(
        full_name, current_version, candidate_version
    );

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
