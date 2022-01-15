#!/bin/zsh -f

# LEPTONICA -- https://github.com/DanBloomberg/leptonica

scriptpath=$0:A
parentdir=${scriptpath%/*}
scriptname=${scriptpath##*/}

if ! source $parentdir/project_environment.sh; then
  echo "build_leptonica.sh: error sourcing $parentdir/project_environment.sh"
  exit 1
fi

if [[ -n $1 ]] && [[ $1 == 'clean' ]]; then
  deleted=$(find $ROOT -name '*lept*' -prune -print -exec rm -rf {} \;)
  if [[ -n $deleted ]]; then
    echo "$scriptname: deleted:"
    echo $deleted
  else
    echo "$scriptname: clean"
  fi
  exit 0
fi

name='leptonica-1.82.0'
print "\n======== $name ========"

# --  Download / Extract  -----------------------------------------------------

targz=$name.tar.gz
url="https://github.com/DanBloomberg/leptonica/releases/download/1.82.0/$targz"

download $name $url $targz || exit 1
extract $name $targz || exit 1

# --  Preconfigure  -----------------------------------------------------------

print -n 'Preconfiguring... '
xc cd $SOURCES/$name || exit 1
xl $name '2_preconfig' ./autogen.sh || exit 1
print 'done.'

# --  Config / Make / Install  ------------------------------------------------

# Legit Apple targets for the Simulator cannot be parsed by legit config.sub
dirname=$name
print -- "--**!!**-- Overriding \$SOURCES/$dirname/config/config.sub with $PROJECTDIR/config.sub.patched"
cp $PROJECTDIR/config.sub.patched $SOURCES/$dirname/config/config.sub || { echo "Error: could not find $PROJECTDIR/config.sub.patched"; exit 1 }

# ios_arm64
export ARCH='arm64'
export TARGET='arm64-apple-ios15.2'
export PLATFORM='iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk'
export PLATFORM_MIN_VERSION='-miphoneos-version-min=15.2'

zsh $parentdir/config-make-install_leptonica.sh $name 'ios_arm64' || exit 1

# ios_arm64_sim
export ARCH='arm64'
export TARGET='arm64-apple-ios15.2-simulator'
export PLATFORM='iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk'
export PLATFORM_MIN_VERSION='-miphoneos-version-min=15.2'

zsh $parentdir/config-make-install_leptonica.sh $name 'ios_arm64_sim' || exit 1

# ios_x86_64_sim
export ARCH='x86_64'
export TARGET='x86_64-apple-ios15.2-simulator'
export PLATFORM='iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk'
export PLATFORM_MIN_VERSION='-mios-simulator-version-min=15.2'

zsh $parentdir/config-make-install_leptonica.sh $name 'ios_x86_64_sim' || exit 1

# macos_x86_64
export ARCH='x86_64'
export TARGET='x86_64-apple-macos12.0'
export PLATFORM='MacOSX.platform/Developer/SDKs/MacOSX.sdk'
export PLATFORM_MIN_VERSION='-mmacosx-version-min=12.0'

zsh $parentdir/config-make-install_leptonica.sh $name 'macos_x86_64' || exit 1

# macos_arm64
export ARCH='arm64'
export TARGET='arm64-apple-macos12.0'
export PLATFORM='MacOSX.platform/Developer/SDKs/MacOSX.sdk'
export PLATFORM_MIN_VERSION='-mmacosx-version-min=12.0'

zsh $parentdir/config-make-install_leptonica.sh $name 'macos_arm64' || exit 1

# --  Lipo  -------------------------------------------------------------------

xc mkdir -p $ROOT/lib

print -n 'lipo: ios... '
xl $name '6_ios_lipo' \
  xcrun lipo $ROOT/ios_arm64/lib/liblept.a \
  -create -output $ROOT/lib/liblept-ios.a ||
  exit 1
print 'done.'

print -n 'lipo: sim... '
xl $name '6_sim_lipo' \
  xcrun lipo $ROOT/ios_arm64_sim/lib/liblept.a $ROOT/ios_x86_64_sim/lib/liblept.a \
  -create -output $ROOT/lib/liblept-sim.a ||
  exit 1
print 'done.'

print -n 'lipo: macos... '
xl $name '6_macos_lipo' \
  xcrun lipo $ROOT/macos_x86_64/lib/liblept.a $ROOT/macos_arm64/lib/liblept.a \
  -create -output $ROOT/lib/liblept-macos.a ||
  exit 1
print 'done.'

# --  Copy headers  -----------------------------------------------------------

xc mkdir -p $ROOT/include/leptonica
xc cp $ROOT/ios_arm64/include/leptonica/* $ROOT/include/leptonica
