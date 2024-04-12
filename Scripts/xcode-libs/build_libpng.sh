#!/bin/zsh -f
[ -z $TBE_PROJECTDIR ] && { echo "
Error: The TBE_PROJECTDIR env var is not set.\n
-   If you are manually runing this build, set this var to the path of your
    TesseractBuild project's directory and re-run, e.g.\n
        export TBE_PROJECTDIR=\$(pwd)\n
-   If you are seeing this after calling one of the Build_All.sh scripts,
    double-check that the script is correctly setting the TBE_PROJECTDIR env var.
"; exit 1 }

source $TBE_PROJECTDIR/Scripts/set_env.sh

thisAbsPath=${0:A}
parentPath=${thisAbsPath%/*}

name='libpng-1.6.42'
targz=$name.tar.gz
url="https://downloads.sourceforge.net/project/libpng/libpng16/1.6.42/$targz"
dirname=$name

print "\n======== $name ========"

# --  Clean  ------------------------------------------------------------------

if [[ $1 == 'clean' ]]; then
  files=$(find $ROOT -name '*png*.*' -print)
  clean $files && exit 0 || exit 1
fi

# --  Assert config.sub.patched  ----------------------------------------------

checkConfigSub || exit 1

# --  Download / Extract  -----------------------------------------------------

download $name $url $targz
extract $name $targz $dirname

# --  Config / Make / Install  ------------------------------------------------

configSub=$SOURCES/$dirname/config.sub
print -n "Overriding ${configSub/$SOURCES/\$SOURCES}... "
xc cp $CONFIG_SUB_PATCHED $configSub || exit 1
print 'done.'

configMakeInstall=$parentPath/config-make-install_libpng.sh

# ios_arm64
export ARCH='arm64'
export TARGET='arm64-apple-ios15.2'
export PLATFORM='iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk'
export PLATFORM_MIN_VERSION='-miphoneos-version-min=15.2'

zsh $configMakeInstall $name 'ios_arm64' $dirname || exit 1

# ios_arm64_sim
export ARCH='arm64'
export TARGET='arm64-apple-ios15.2-simulator'
export PLATFORM='iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk'
export PLATFORM_MIN_VERSION='-miphoneos-version-min=15.2'

zsh $configMakeInstall $name 'ios_arm64_sim' $dirname || exit 1

# ios_x86_64_sim
export ARCH='x86_64'
export TARGET='x86_64-apple-ios15.2-simulator'
export PLATFORM='iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk'
export PLATFORM_MIN_VERSION='-mios-simulator-version-min=15.2'

zsh $configMakeInstall $name 'ios_x86_64_sim' $dirname || exit 1

# macos_x86_64
export ARCH='x86_64'
export TARGET='x86_64-apple-macos12.0'
export PLATFORM='MacOSX.platform/Developer/SDKs/MacOSX.sdk'
export PLATFORM_MIN_VERSION='-mmacosx-version-min=12.0'

zsh $configMakeInstall $name 'macos_x86_64' $dirname || exit 1

# macos_arm64
export ARCH='arm64'
export TARGET='arm64-apple-macos12.0'
export PLATFORM='MacOSX.platform/Developer/SDKs/MacOSX.sdk'
export PLATFORM_MIN_VERSION='-mmacosx-version-min=12.0'

zsh $configMakeInstall $name 'macos_arm64' $dirname || exit 1

# --  Lipo  -------------------------------------------------------------------

xc mkdir -p $ROOT/lib

print -n 'lipo: ios... '

arm64Lib_a=$ROOT/ios_arm64/lib/libpng16.a
iosLib_a=$ROOT/lib/libpng16-ios.a

xl $name '5_ios_lipo' \
  xcrun lipo $arm64Lib_a -create -output $iosLib_a || \
exit 1

print 'done.'

print -n 'lipo: sim... '

arm64Lib_a=$ROOT/ios_arm64_sim/lib/libpng16.a
x86Lib_a=$ROOT/ios_x86_64_sim/lib/libpng16.a
simulatorLib_a=$ROOT/lib/libpng16-sim.a

xl $name '5_sim_lipo' \
  xcrun lipo $arm64Lib_a $x86Lib_a -create -output $simulatorLib_a \
|| exit 1

print 'done.'

print -n 'lipo: macos... '

arm64Lib_a=$ROOT/macos_arm64/lib/libpng16.a
x86Lib_a=$ROOT/macos_x86_64/lib/libpng16.a
macosLib_a=$ROOT/lib/libpng16-macos.a

xl $name '5_macos_lipo' \
  xcrun lipo $arm64Lib_a $x86Lib_a -create -output $macosLib_a \
|| exit 1

print 'done.'

xc cd $ROOT/lib
xc ln -fs libpng16-ios.a libpng-ios.a
xc ln -fs libpng16-macos.a libpng-macos.a
xc ln -fs libpng16-sim.a libpng-sim.a

# xc ln -fs libpng16.a libpng.a  # leptonica and tesseract need the lib named this way

# --  Copy headers  -----------------------------------------------------------

xc mkdir -p $ROOT/include/libpng16

xc cp $ROOT/ios_arm64/include/libpng16/* $ROOT/include/libpng16
xc cp $ROOT/ios_arm64/include/png*.h     $ROOT/include
