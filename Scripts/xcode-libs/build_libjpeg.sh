#!/bin/zsh -f

name='jpeg.v9d'
targz='jpegsrc.v9d.tar.gz'
url="http://www.ijg.org/files/$targz"
dirname='jpeg-9d'

print "\n======== $name ========"

thisAbsPath=${0:A}
parentPath=${thisAbsPath%/*}
scriptName=${thisAbsPath##*/}

setEnvPath=$parentPath/../set_env.sh
source $setEnvPath || { echo "ERROR could not source $setEnvPath"; exit 1 }


# --  Clean  ------------------------------------------------------------------

if [[ $1 == 'clean' ]]; then
  files=$(find $ROOT \( -name '*jpeg*' -o -name '*jpg*' -o -name 'j*.h' \) -print)
  clean $files || exit 1
  exit 0
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

# ios_arm64
export ARCH='arm64'
export TARGET='arm64-apple-ios15.2'
export PLATFORM='iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk'
export PLATFORM_MIN_VERSION='-miphoneos-version-min=15.2'

zsh $parentPath/config-make-install_libjpeg.sh $name 'ios_arm64' $dirname || exit 1

# ios_arm64_sim
export ARCH='arm64'
export TARGET='arm64-apple-ios15.2-simulator'
export PLATFORM='iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk'
export PLATFORM_MIN_VERSION='-miphoneos-version-min=15.2'

zsh $parentPath/config-make-install_libjpeg.sh $name 'ios_arm64_sim' $dirname || exit 1

# ios_x86_64_sim
export ARCH='x86_64'
export TARGET='x86_64-apple-ios15.2-simulator'
export PLATFORM='iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk'
export PLATFORM_MIN_VERSION='-mios-simulator-version-min=15.2'

zsh $parentPath/config-make-install_libjpeg.sh $name 'ios_x86_64_sim' $dirname || exit 1

# macos_x86_64
export ARCH='x86_64'
export TARGET='x86_64-apple-macos12.0'
export PLATFORM='MacOSX.platform/Developer/SDKs/MacOSX.sdk'
export PLATFORM_MIN_VERSION='-mmacosx-version-min=12.0'

zsh $parentPath/config-make-install_libjpeg.sh $name 'macos_x86_64' $dirname || exit 1

# macos_arm64
export ARCH='arm64'
export TARGET='arm64-apple-macos12.0'
export PLATFORM='MacOSX.platform/Developer/SDKs/MacOSX.sdk'
export PLATFORM_MIN_VERSION='-mmacosx-version-min=12.0'

zsh $parentPath/config-make-install_libjpeg.sh $name 'macos_arm64' $dirname || exit 1

# --  Lipo  -------------------------------------------------------------------

xc mkdir -p $ROOT/lib

print -n 'lipo: ios... '

arm64Lib_a=$ROOT/ios_arm64/lib/libjpeg.a
iosLib_a=$ROOT/lib/libjpeg-ios.a

xl $name '5_ios_lipo' \
  xcrun lipo $arm64Lib_a -create -output $iosLib_a || \
exit 1

print 'done.'

print -n 'lipo: sim... '

arm64Lib_a=$ROOT/ios_arm64_sim/lib/libjpeg.a
x86Lib_a=$ROOT/ios_x86_64_sim/lib/libjpeg.a
simulatorLib_a=$ROOT/lib/libjpeg-sim.a

xl $name '5_sim_lipo' \
  xcrun lipo $arm64Lib_a $x86Lib_a -create -output $simulatorLib_a \
|| exit 1

print 'done.'

print -n 'lipo: macos... '

arm64Lib_a=$ROOT/macos_arm64/lib/libjpeg.a
x86Lib_a=$ROOT/macos_x86_64/lib/libjpeg.a
macosLib_a=$ROOT/lib/libjpeg-macos.a

xl $name '5_macos_lipo' \
  xcrun lipo $arm64Lib_a $x86Lib_a -create -output $macosLib_a \
|| exit 1

print 'done.'

# --  Copy headers  -----------------------------------------------------------

xc mkdir -p $ROOT/include

xc cp $ROOT/ios_arm64/include/j*.h $ROOT/include
