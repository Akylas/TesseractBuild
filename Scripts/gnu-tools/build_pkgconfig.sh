#!/bin/zsh -f

name='pkg-config-0.29.2'
targz=$name.tar.gz
url="https://pkg-config.freedesktop.org/releases/$targz"


thisAbsPath=${0:A}
parentPath=${thisAbsPath%/*}
scriptName=${thisAbsPath##*/}
setEnvPath=$parentPath/../set_env.sh


print "\n======== $name ========"

source $setEnvPath || { echo "$scriptName: error sourcing $setEnvPath"; exit 1 }

if [[ -n $1 ]] && [[ $1 == 'clean' ]]; then
  deleted=$(find $ROOT -name '*pkg*' -prune -print -exec rm -rf {} \;)
  if [[ -n $deleted ]]; then
    echo "$scriptName: deleted:"
    echo $deleted
  else
    echo "$scriptName: clean"
  fi
  exit 0
fi

if {
  [ -f $ROOT/bin/pkg-config ] &&
    version=$($ROOT/bin/pkg-config --version) &&
    [[ $version == *'0.29.2'* ]]
}; then
  print "Skipped build, found $ROOT/bin/pkg-config w/version 0.29.2"
  exit 0
fi

# --  Download / Extract  -----------------------------------------------------


download $name $url $targz
extract $name $targz

# --  Config / Make / Install  ------------------------------------------------

xc mkdir -p $SOURCES/$name/x86
xc cd $SOURCES/$name/x86

print -n 'x86: '

print -n 'configuring... '
xl $name '2_config_x86' \
  ../configure --with-internal-glib "--prefix=$ROOT" || exit 1
print -n 'done, '

print -n 'making... '
xl $name '3_clean_x86' make clean || exit 1
xl $name '3_make_x86' make -j || exit 1
print -n 'done, '

print -n 'installing... '
xl $name '4_install_x86' make install || exit 1
print 'done.'
