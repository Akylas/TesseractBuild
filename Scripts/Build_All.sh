#!/bin/zsh -f

# Builds gnu-tools, then builds xcode-libs

thisAbsPath=${0:A}
scriptsDir=${thisAbsPath%/*}
TBE_PROJECTDIR=${scriptsDir%/Scripts}

export TBE_PROJECTDIR

print "\nRunning ${thisAbsPath/$TBE_PROJECTDIR/\$TBE_PROJECTDIR}"

if [[ $1 == 'clean-all' ]]; then
  zsh $scriptsDir/gnu-tools/Build_All.sh clean-all || exit 1
  zsh $scriptsDir/xcode-libs/Build_All.sh clean-all || exit 1
  
  exit 0
fi

zsh $scriptsDir/gnu-tools/Build_All.sh || exit 1
zsh $scriptsDir/xcode-libs/Build_All.sh || exit 1

