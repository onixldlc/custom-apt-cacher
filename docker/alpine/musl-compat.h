// alpine/musl portability shim for apt-cacher-ng build.
// force-included via CMAKE_CXX_FLAGS in docker/alpine/Dockerfile.
// only affects alpine builds; debian/ubuntu do not use this header.

#pragma once

// musl doesn't define suseconds_t transitively through the headers meta.h pulls in.
#include <sys/time.h>

// musl + newer libstdc++ don't transitively include <cstdint>; ahttpurl.h and
// portutils.h use uint16_t/uint32_t/etc without an explicit include.
#include <cstdint>

// glibc's <sys/types.h> provides `uint` under __USE_MISC. musl does not.
// several .cc files use (uint) casts. define the typedef once here so all
// compilation units see it.
#ifdef __cplusplus
extern "C" {
#endif
typedef unsigned int uint;
#ifdef __cplusplus
}
#endif
