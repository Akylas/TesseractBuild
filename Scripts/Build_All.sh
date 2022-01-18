#!/bin/zsh -f

# Builds gnu-tools, then builds xcode-libs

thisAbsPath=${0:A}
parentPath=${thisAbsPath%/*}

echo "Running $thisAbsPath"

if [[ $1 == 'clean-all' ]]; then
  zsh $parentPath/gnu-tools/Build_All.sh clean-all || exit 1
  zsh $parentPath/xcode-libs/Build_All.sh clean-all || exit 1
  
  exit 0
fi

zsh $parentPath/gnu-tools/Build_All.sh || exit 1
zsh $parentPath/xcode-libs/Build_All.sh || exit 1

