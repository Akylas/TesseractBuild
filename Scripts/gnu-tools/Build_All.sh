#!/bin/zsh -f

# Build a small suite of GNU tools before we can build the Xcode libs.

thisAbsPath=${0:A}
parentPath=${thisAbsPath%/*}

print "\nRunning $thisAbsPath"

if [[ -n $1 ]] && [[ $1 == 'clean-all' ]]; then
  zsh $parentPath/build_autoconf.sh clean
  zsh $parentPath/build_automake.sh clean
  zsh $parentPath/build_pkgconfig.sh clean
  zsh $parentPath/build_libtool.sh clean
  exit 0
fi

zsh $parentPath/build_autoconf.sh || exit 1
zsh $parentPath/build_automake.sh || exit 1
zsh $parentPath/build_pkgconfig.sh || exit 1
zsh $parentPath/build_libtool.sh || exit 1
