#!/bin/zsh -f

# Build Tesseract OCR and the libs it depends on

thisAbsPath=${0:A}
parentPath=${thisAbsPath%/*}
scriptsDir=${parentPath%/xcode-libs}
TBE_PROJECTDIR=${scriptsDir%/Scripts}

export TBE_PROJECTDIR

print "\nRunning ${thisAbsPath/$TBE_PROJECTDIR/\$TBE_PROJECTDIR}"

if [[ -n $1 ]] && [[ $1 == 'clean-all' ]]; then
  zsh $parentPath/build_libjpeg.sh clean
  zsh $parentPath/build_libpng.sh clean
  zsh $parentPath/build_libtiff.sh clean
  zsh $parentPath/build_leptonica.sh clean
  zsh $parentPath/build_tesseract.sh clean
  exit 0
fi

zsh $parentPath/build_libjpeg.sh
zsh $parentPath/build_libpng.sh
zsh $parentPath/build_libtiff.sh
zsh $parentPath/build_leptonica.sh
zsh $parentPath/build_tesseract.sh
