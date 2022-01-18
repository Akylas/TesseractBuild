#!/bin/zsh -f

# Builds gnu-tools, then builds xcode-libs

thisAbsPath=${0:A}
parentPath=${thisAbsPath%/*}

echo "Running $thisAbsPath"

if [[ -n $1 ]] && [[ $1 == 'clean-all' ]]; then
  zsh $parentPath/gnu-tools/Build_All.sh clean-all
  zsh $parentPath/xcode-libs/Build_All.sh clean-all
  
  exit 0
fi

zsh $parentPath/gnu-tools/Build_All.sh
zsh $parentPath/xcode-libs/Build_All.sh

