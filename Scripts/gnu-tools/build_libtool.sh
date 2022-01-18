#!/bin/zsh -f

# LIBTOOL -- https://www.gnu.org/software/libtool/

thisAbsPath=${0:A}
parentPath=${thisAbsPath%/*}
scriptName=${thisAbsPath##*/}

setEnvPath=$parentPath/../set_env.sh
source $setEnvPath || { echo "$scriptName: error sourcing $setEnvPath"; exit 1 }

if [[ -n $1 ]] && [[ $1 == 'clean' ]]; then
  deleted=$(find $ROOT -name 'libtool*' -prune -print -exec rm -rf {} \;)
  if [[ -n $deleted ]]; then
    echo "$scriptName: deleted:"
    echo $deleted
  else
    echo "$scriptName: clean"
  fi
  exit 0
fi

name='libtool-2.4.6'

print "\n======== $name ========"

if {
  [ -f $ROOT/bin/libtool ] &&
    version=$($ROOT/bin/libtool --version) &&
    [[ $version == *'2.4.6'* ]]
}; then
  echo "Skipped build, found $ROOT/bin/libtool w/version 2.4.6"
  exit 0
fi

# --  Download / Extract  -----------------------------------------------------

targz=$name.tar.gz
url="http://ftp.gnu.org/gnu/libtool/$targz"

download $name $url $targz
extract $name $targz

# --  Config / Make / Install  ------------------------------------------------

xc mkdir -p $SOURCES/$name/x86
xc cd $SOURCES/$name/x86 || exit 1

print -n 'x86: '

print -n 'configuring... '
xl $name '2_config_x86' ../configure --prefix=$ROOT || exit 1
print -n 'done, '

print -n 'making... '
xl $name '3_clean_x86' make clean || exit 1
xl $name '3_make_x86' make -j || exit 1
print -n 'done, '

print -n 'installing... '
xl $name '4_install_x86' make install || exit 1
print 'done.'
