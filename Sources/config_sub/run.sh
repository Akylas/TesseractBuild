#!/bin/zsh -f

# Get absolute path to this script
thisAbsPath=${0:A}

# Get immediate relative info
scriptName=${thisAbsPath##*/}
parentPath=${thisAbsPath%/*}

# Assert we are *named what* we should be
[[ $scriptName != 'run.sh' ]] && echo "Warning: expected this script to be named \"run.sh\", instead it's \"$scriptName\"."

# Assert we are *where* we should be
parentName=${parentPath##*/}
[[ $parentName != 'config_sub' ]] && echo "Warning: expected this script's parent directory to be \"config_sub\", instead it's \"$parentName\"."

# Getting on with it...

url='https://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=HEAD'

print -n 'Downloading latest config.sub... '
curl -sSL --fail -o $parentPath/config.sub.latest $url || { echo "Error: failed to download $url"; exit 1 }
print 'done.'

print -n 'Duplicating before patch... '
cp $parentPath/config.sub.latest $parentPath/config.sub.patched || { echo 'Error: failed to duplicate file'; exit 1 }
print 'done.'

print -n "Applying patch to allow 'simulator'... "
patch $parentPath/config.sub.patched $parentPath/erase_simulator.patch || { echo 'Error: Failed to patch'; exit 1 }
print 'done.'
