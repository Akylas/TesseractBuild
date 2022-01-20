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

name='automake-1.16.5'
targz=$name.tar.gz
url="http://ftp.gnu.org/gnu/automake/$targz"
dirname=$name

print "\n======== $name ========"

# --  Clean  ------------------------------------------------------------------

if [[ $1 == 'clean' ]]; then
  # See note at bottom, "Copy headers", for why 'j*.h'
  files=$(find $ROOT \
      \( -name 'aclocal' -o -name 'automake' \) \
      -a -type f -print)
  clean $files && exit 0 || exit 1
fi

# --  Check if already build  -------------------------------------------------

if {
  [ -f $ROOT/bin/automake ] &&
    version=$($ROOT/bin/automake --version) &&
    [[ $version == *'1.16.5'* ]]
}; then
  print "Skipped build, found \$ROOT/bin/automake w/version 1.16.5"
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
xl $name '2_config_x86' ../configure "--prefix=$ROOT" || exit 1
print -n 'done, '

print -n 'making... '
xl $name '3_clean_x86' make clean || exit 1
xl $name '3_make_x86' make -j || exit 1
print -n 'done, '

print -n 'installing... '
xl $name '4_install_x86' make install || exit 1
print 'done.'
