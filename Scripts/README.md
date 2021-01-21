# Miscellaneous

## Problem with -lrt lib in Tesseract make

Main problem is:

```none
warning: /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/ranlib: archive library: .libs/libtesseract_opencl.a the table of contents is empty (no object file members in the library define global symbols)
ld: library not found for -lrt
clang: error: linker command failed with exit code 1 (use -v to see invocation)
make[2]: *** [tesseract] Error 1
make[1]: *** [all-recursive] Error 1
make: *** [all] Error 2
```

This `-lrt` option is for an old library.  Searched online and the common solution for `ld: library not found for -lrt` and `clang: error: linker command failed with exit code 1 (use -v to see invocation)` is "take it out".

The solution ended up being to have **config.sub** spit out `arm-apple-darwin64`, that way the **configure** script catches `*darwin*` as a host it expects and sets the correct `ADD_RT_*` flags:

```sh
...
*darwin*)
  OPENCL_LIBS=""
  OPENCL_INC=""
  if false; then
    ADD_RT_TRUE=
    ADD_RT_FALSE='#'   # <-- I have no idea, logically (if false?), why this works, but this is line we want evaluated to avoid the RT flag
  else
    ADD_RT_TRUE='#'
    ADD_RT_FALSE=
  fi
...
```

The `TARGET` parameter remains like `arm64-apple-iphoneos14.3`.

See the "--**!!**-- Overriding..." lines in the build scripts for the top-level libraries.

This is also documented in the Lessons Learned section in the main README.

## Tesseract Version / Source

Not the clearest to find, but we're using 4.1.1, and [the manual](https://tesseract-ocr.github.io/tessdoc/) has a link to the TARGZ file.

## libtiff header

**tiffconf.h** has one value with two different definitions between **arm64** and **x86_64**, and might affect you if you are building for macOS.

```sh
% diff -r Root/ios_arm64/include Root/macos_x86_64/include
diff -r Root/ios_arm64/include/tiffconf.h Root/macos_x86_64/include/tiffconf.h
48c48
< #define HOST_FILLORDER FILLORDER_MSB2LSB
---
> #define HOST_FILLORDER FILLORDER_LSB2MSB
```

From, <https://www.awaresystems.be/imaging/tiff/tifftags/fillorder.html>:

> LibTiff defines these values:
>
> FILLORDER_MSB2LSB = 1;
> FILLORDER_LSB2MSB = 2;
>
> In practice, the use of FillOrder=2 is very uncommon, and is not recommended.

From, <http://www.libtiff.org/internals.html>:

> Native CPU byte order is determined on the fly by the library and does not need to be specified. The HOST_FILLORDER and HOST_BIGENDIAN definitions are not currently used, but may be employed by codecs for optimization purposes.

As **ios_arm64** seems the more important library, by default those headers will be used.

*If you are making a macOS app and have problems linking/referencing the API, consider adjusting this final copy.*

## Troubleshooting

The errors coming out of the configure step can be difficult to understand if you only read the **Step#_config.err** in the **Logs** directory.

The key to debugging configure errors is to check the **config.log** for a given build in that build's **Sources** directory.

Given this error running build_all.sh:

```none
macos_x86_64: configuring... ERROR running ../configure CC=...
...
...
ERROR see ~/$PROJECTDIR/Logs/tesseract-4.1.1/3_config_macos_x86_64.err for more details
```

Looking at **Logs/tesseract-4.1.1/3_config_macos_x86_64.err**:

```none
configure: error: in `~/$PROJECTDIR/Sources/tesseract-4.1.1/macos_x86_64':
configure: error: C++ compiler cannot create executables
See `config.log' for more details
```

The last line, *See `config.log' for more details* is the true clue.

Here's the telling error message from **Sources/tesseract-4.1.1/macos_x86_64/config.log**:

```none
...
ld: library not found for -lpng
clang: error: linker command failed with exit code 1 (use -v to see invocation)
...
```

In this case, I had just clobbered all macos_x86_64 binaries/libraries including **macos_x86_64/lib/libpng16.a**.  And this is what `./configure` failed on.

Other "errors" like the following may not really be errors, it's just configure trying out different configurations:

```none
configure:2663: /Applications/Xcode.app/Contents/Developer/usr/bin/g++ -V >&5
clang: error: unsupported option '-V -Wno-objc-signed-char-bool-implicit-int-conversion'
clang: error: no input files
```

and:

```none
configure:2663: /Applications/Xcode.app/Contents/Developer/usr/bin/g++ -qversion >&5
clang: error: unknown argument '-qversion'; did you mean '--version'?
clang: error: no input files
```
