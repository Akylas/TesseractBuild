#!/bin/zsh -f

name='pkg-config-0.29.2'
targz=$name.tar.gz
url="https://pkg-config.freedesktop.org/releases/$targz"
dirname=$name

print "\n======== $name ========"

thisAbsPath=${0:A}
parentPath=${thisAbsPath%/*}
scriptName=${thisAbsPath##*/}

setEnvPath=$parentPath/../set_env.sh
source $setEnvPath || { echo "ERROR could not source $setEnvPath"; exit 1 }


# --  Clean  ------------------------------------------------------------------

if [[ $1 == 'clean' ]]; then
  # See note at bottom, "Copy headers", for why 'j*.h'
  files=$(find $ROOT \
      \( -name '*pkg*' \) \
      -a -type f -print)
  clean $files && exit 0 || exit 1
fi

# --  Check if already build  -------------------------------------------------

if {
  [ -f $ROOT/bin/pkg-config ] &&
    version=$($ROOT/bin/pkg-config --version) &&
    [[ $version == *'0.29.2'* ]]
}; then
  print "Skipped build, found \$ROOT/bin/pkg-config w/version 0.29.2"
  exit 0
fi

# --  Download / Extract  -----------------------------------------------------


download $name $url $targz
extract $name $targz $dirname

# --  Config / Make / Install  ------------------------------------------------

xc mkdir -p $SOURCES/$name/x86
xc cd $SOURCES/$name/x86 || exit 1

print -n 'x86: '

print -n 'configuring... '
xl $name '2_config_x86' ../configure "--prefix=$ROOT" --with-internal-glib || exit 1
print -n 'done, '

print -n 'making... '
xl $name '3_clean_x86' make clean || exit 1
xl $name '3_make_x86' make -j || exit 1
print -n 'done, '

print -n 'installing... '
xl $name '4_install_x86' make install || exit 1
print 'done.'
