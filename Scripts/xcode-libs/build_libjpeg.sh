#!/bin/zsh -f


name='jpeg.v9d'
targz='jpegsrc.v9d.tar.gz'
url="http://www.ijg.org/files/$targz"
dirname='jpeg-9d'


thisAbsPath=${0:A}
parentPath=${thisAbsPath%/*}
scriptName=${thisAbsPath##*/}
setEnvPath=$parentPath/../set_env.sh


print "\n======== $name ========"

source $setEnvPath || { echo "$scriptName: error sourcing $setEnvPath"; exit 1 }

# Clean
if [[ -n $1 ]] && [[ $1 == 'clean' ]]; then
  FILES=("${(@f)$(find $ROOT \( -name '*jpeg*' -o -name '*jpg*' -o -name 'j*.h' \) -print)}")
  if [[ -z $FILES ]]; then
    echo "$scriptName: already clean."
  else
    # Loop over files, removing, then testing if the parent-dir is empty
    for FILE in $FILES; do
      print -n "Deleting $FILE ..."
      rm $FILE && print ' done.'
      DIR=${FILE%/*}  # substitue filename with nothing
      rmdir $DIR 2>/dev/null && echo "Deleted $DIR"
    done
  fi
  exit 0
fi


# --  Download / Extract  -----------------------------------------------------


download $name $url $targz
extract $name $targz $dirname

# --  Config / Make / Install  ------------------------------------------------

# Legit Apple targets for the Simulator cannot be parsed by legit config.sub, see Scripts/README.md
print -- "--**!!**-- Overriding \$SOURCES/$dirname/config.sub with $SCRIPTSDIR/config.sub.patched"
cp $SCRIPTSDIR/config.sub.patched $SOURCES/$dirname/config.sub || { echo "Error: could not find $SCRIPTSDIR/config.sub.patched"; exit 1 }

# ios_arm64
export ARCH='arm64'
export TARGET='arm64-apple-ios15.2'
export PLATFORM='iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk'
export PLATFORM_MIN_VERSION='-miphoneos-version-min=15.2'

zsh $parentdir/config-make-install_libjpeg.sh $name 'ios_arm64' $dirname || exit 1

# ios_arm64_sim
export ARCH='arm64'
export TARGET='arm64-apple-ios15.2-simulator'
export PLATFORM='iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk'
export PLATFORM_MIN_VERSION='-miphoneos-version-min=15.2'

zsh $parentdir/config-make-install_libjpeg.sh $name 'ios_arm64_sim' $dirname || exit 1

# ios_x86_64_sim
export ARCH='x86_64'
export TARGET='x86_64-apple-ios15.2-simulator'
export PLATFORM='iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk'
export PLATFORM_MIN_VERSION='-mios-simulator-version-min=15.2'

zsh $parentdir/config-make-install_libjpeg.sh $name 'ios_x86_64_sim' $dirname || exit 1

# macos_x86_64
export ARCH='x86_64'
export TARGET='x86_64-apple-macos12.0'
export PLATFORM='MacOSX.platform/Developer/SDKs/MacOSX.sdk'
export PLATFORM_MIN_VERSION='-mmacosx-version-min=12.0'

zsh $parentdir/config-make-install_libjpeg.sh $name 'macos_x86_64' $dirname || exit 1

# macos_arm64
export ARCH='arm64'
export TARGET='arm64-apple-macos12.0'
export PLATFORM='MacOSX.platform/Developer/SDKs/MacOSX.sdk'
export PLATFORM_MIN_VERSION='-mmacosx-version-min=12.0'

zsh $parentdir/config-make-install_libjpeg.sh $name 'macos_arm64' $dirname || exit 1

# --  Lipo  -------------------------------------------------------------------
xc mkdir -p $ROOT/lib

print -n 'lipo: ios... '
xl $name '5_ios_lipo' \
  xcrun lipo $ROOT/ios_arm64/lib/libjpeg.a \
  -create -output $ROOT/lib/libjpeg-ios.a ||
  exit 1
print 'done.'

print -n 'lipo: sim... '
xl $name '5_sim_lipo' \
  xcrun lipo $ROOT/ios_arm64_sim/lib/libjpeg.a $ROOT/ios_x86_64_sim/lib/libjpeg.a \
  -create -output $ROOT/lib/libjpeg-sim.a ||
  exit 1
print 'done.'

print -n 'lipo: macos... '
xl $name '5_macos_lipo' \
  xcrun lipo $ROOT/macos_x86_64/lib/libjpeg.a $ROOT/macos_arm64/lib/libjpeg.a \
  -create -output $ROOT/lib/libjpeg-macos.a ||
  exit 1
print 'done.'

# --  Copy headers  -----------------------------------------------------------

xc mkdir -p $ROOT/include
xc cp $ROOT/ios_arm64/include/j*.h $ROOT/include
