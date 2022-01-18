#!/bin/zsh -f

# LIBTIFF -- https://gitlab.com/libtiff/libtiff

thisAbsPath=${0:A}
parentPath=${thisAbsPath%/*}
scriptName=${thisAbsPath##*/}

setEnvPath=$parentPath/../set_env.sh
source $setEnvPath || { echo "$scriptName: error sourcing $setEnvPath"; exit 1 }

if [[ -n $1 ]] && [[ $1 == 'clean' ]]; then
  deleted=$(find $ROOT -name '*tiff*' -prune -print -exec rm -rf {} \;)
  if [[ -n $deleted ]]; then
    echo "$scriptName: deleted:"
    echo $deleted
  else
    echo "$scriptName: clean"
  fi
  exit 0
fi

name='tiff-4.3.0'

print "\n======== $name ========"

# --  Download / Extract  -----------------------------------------------------

targz=$name.tar.gz
url="http://download.osgeo.org/libtiff/$targz"

download $name $url $targz
extract $name $targz

# --  Config / Make / Install  ------------------------------------------------

# Legit Apple targets for the Simulator cannot be parsed by legit config.sub, see Scripts/README.md
checkConfigSub
dirname=$name
print -- "--**!!**-- Overriding \$SOURCES/$dirname/config/config.sub with $SCRIPTSDIR/config.sub.patched"
cp $SCRIPTSDIR/config.sub.patched $SOURCES/$dirname/config/config.sub || { echo "Error: could not find $SCRIPTSDIR/config.sub.patched"; exit 1 }

# ios_arm64
export ARCH='arm64'
export TARGET='arm64-apple-ios15.2'
export PLATFORM='iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk'
export PLATFORM_MIN_VERSION='-miphoneos-version-min=15.2'

zsh $parentdir/config-make-install_libtiff.sh $name 'ios_arm64' || exit 1

# ios_arm64_sim
export ARCH='arm64'
export TARGET='arm64-apple-ios15.2-simulator'
export PLATFORM='iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk'
export PLATFORM_MIN_VERSION='-miphoneos-version-min=15.2'

zsh $parentdir/config-make-install_libtiff.sh $name 'ios_arm64_sim' || exit 1

# ios_x86_64_sim
export ARCH='x86_64'
export TARGET='x86_64-apple-ios15.2-simulator'
export PLATFORM='iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk'
export PLATFORM_MIN_VERSION='-mios-simulator-version-min=15.2'

zsh $parentdir/config-make-install_libtiff.sh $name 'ios_x86_64_sim' || exit 1

# macos_x86_64
export ARCH='x86_64'
export TARGET='x86_64-apple-macos12.0'
export PLATFORM='MacOSX.platform/Developer/SDKs/MacOSX.sdk'
export PLATFORM_MIN_VERSION='-mmacosx-version-min=12.0'

zsh $parentdir/config-make-install_libtiff.sh $name 'macos_x86_64' || exit 1

# macos_arm64
export ARCH='arm64'
export TARGET='arm64-apple-macos12.0'
export PLATFORM='MacOSX.platform/Developer/SDKs/MacOSX.sdk'
export PLATFORM_MIN_VERSION='-mmacosx-version-min=12.0'

zsh $parentdir/config-make-install_libtiff.sh $name 'macos_arm64' || exit 1

# --  Lipo  -------------------------------------------------------------------
xc mkdir -p $ROOT/lib

print -n 'lipo: ios... '
xl $name '5_ios_lipo' \
  xcrun lipo $ROOT/ios_arm64/lib/libtiff.a \
  -create -output $ROOT/lib/libtiff-ios.a ||
  exit 1
print 'done.'

print -n 'lipo: sim... '
xl $name '5_sim_lipo' \
  xcrun lipo $ROOT/ios_arm64_sim/lib/libtiff.a $ROOT/ios_x86_64_sim/lib/libtiff.a \
  -create -output $ROOT/lib/libtiff-sim.a ||
  exit 1
print 'done.'

print -n 'lipo: macos... '
xl $name '5_macos_lipo' \
  xcrun lipo $ROOT/macos_x86_64/lib/libtiff.a $ROOT/macos_arm64/lib/libtiff.a \
  -create -output $ROOT/lib/libtiff-macos.a ||
  exit 1
print 'done.'

# --  Copy headers  -----------------------------------------------------------

xc mkdir -p $ROOT/include
xc cp $ROOT/ios_arm64/include/tiff*.h $ROOT/include
