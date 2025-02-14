#!/bin/zsh
[ -z $ARCH ] || [ -z $TARGET ] || [ -z $PLATFORM ] || [ -z $PLATFORM_MIN_VERSION ] && { echo "
Error: Some required config vars are not set.\n
ARCH:$ARCH
TARGET:$TARGET
PLATFORM:$PLATFORM
PLATFORM_MIN_VERSION:$PLATFORM_MIN_VERSION\n"; exit 1 }

[ -z $TBE_PROJECTDIR ] && { echo "
Error: The TBE_PROJECTDIR env var is not set.\n"; exit 1 }

source $TBE_PROJECTDIR/Scripts/set_env.sh

name=$1
os_arch=$2
dirname=$3
thisLib=$ROOT/$os_arch/lib/libtesseract.a

print -n "$os_arch: "

# Skip build if check returns w/0
checkForXcodeLib $thisLib $ARCH && exit 0

verifyPlatform || exit 1

cflags=(
  "-std=c++17"
  "-stdlib=libc++"
  "-isysroot /Applications/Xcode.app/Contents/Developer/Platforms/$PLATFORM"
  $PLATFORM_MIN_VERSION
  "--target=$TARGET"
  
  "-I$ROOT/$os_arch/"

  '-fembed-bitcode'
  '-no-cpp-precomp'
  '-O3 -g3'
  '-pipe'
)

# sames as cflags, but sans `-fembed-bitcode`
cxxflags=(
  "-std=c++17"
  "-stdlib=libc++"
  "-isysroot /Applications/Xcode.app/Contents/Developer/Platforms/$PLATFORM"
  $PLATFORM_MIN_VERSION
  "--target=$TARGET"

  "-I$ROOT/$os_arch/"

  '-no-cpp-precomp'
  '-O3 -g3'
  '-pipe'
)

config_flags=(
  CC="$(xcode-select -p)/usr/bin/gcc"
  CXX="$(xcode-select -p)/usr/bin/g++"
  CXX_FOR_BUILD="$(xcode-select -p)/usr/bin/g++"
  CFLAGS="$cflags"
  CPPFLAGS="$cflags"
  CXXFLAGS="$cxxflags"
  LDFLAGS="-L$ROOT/$os_arch/lib -L/Applications/Xcode.app/Contents/Developer/Platforms/$PLATFORM/usr/lib/"
  LIBLEPT_HEADERSDIR="$ROOT/$os_arch/include"
  LIBS='-lz -lpng'
  PKG_CONFIG_PATH="$ROOT/$os_arch/lib/pkgconfig"

  "--host=$TARGET"
  "--prefix=$ROOT/$os_arch"

  '--disable-graphics'
  '--disable-legacy'
  '--without-curl'
)

xc mkdir -p $SOURCES/$dirname/$os_arch || exit 1
xc cd $SOURCES/$dirname/$os_arch  || exit 1

# "Step 2" is pre-configure, in build script
print -n 'configuring... '
xl $name "3_config_$os_arch" ../configure $config_flags || exit 1
print -n 'done, '

print -n 'overriding Makefile... '
sed 's/am__append_49 = -lrt/# am__append_49 = -lrt/' Makefile > tmp || { echo "Error: could not sed/comment-out '-lrt' flag to tmp file"; exit 1 }
mv tmp Makefile || { echo 'Error: could not move tmp file back on top of Makefile'; exit 1 }
print -n 'done, '

print -n 'making... '
xl $name "4_clean_$os_arch" make clean || exit 1
xl $name "4_make_$os_arch" make -j V=1 || exit 1
print -n 'done, '

print -n 'installing... '
xl $name "5_install_$os_arch" make install || exit 1
print 'done.'

validateBuiltLib $thisLib $ARCH || exit 1