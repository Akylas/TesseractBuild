#!/bin/zsh -f

scriptpath=$0:A
parentdir=${scriptpath%/*}
scriptname=${scriptpath##*/}

if ! source $parentdir/build/project_environment.sh; then
  echo "$scriptname: error sourcing $parentdir/build/project_environment.sh"
  exit 1
fi

print -n 'Downloading latest config.sub... '
url='https://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=HEAD'
xc curl -sSL --fail -o $SCRIPTSDIR/config.sub.latest $url || { echo "Error: failed to download $url"; exit 1 }
print 'done.'

print -n 'Duplicating before patch... '
xc cp $SCRIPTSDIR/config.sub.latest $SCRIPTSDIR/config.sub.patched || { echo 'Error: failed to duplicate file'; exit 1 }
print 'done.'

print -n "Applying patch to allow 'simulator'... "
xc patch $SCRIPTSDIR/config.sub.patched $SCRIPTSDIR/erase_simulator.patch || { echo 'Error: Failed to patch'; exit 1 }
print 'done.'
