#!/bin/zsh

print -n 'Downloading latest config.sub... '
url='https://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=HEAD'
curl -sSL --fail -o config.sub.latest $url || { echo "Error: failed to download $url"; exit 1 }
print 'done.'

print -n 'Duplicating before patch... '
cp config.sub.latest config.sub.patched || { echo 'Error: failed to duplicate file'; exit 1 }
print 'done.'

print -n "Applying patch to allow 'simulator'... "
patch config.sub.patched erase_simulator.patch || { echo 'Error: Failed to patch'; exit 1 }
print 'done.'
