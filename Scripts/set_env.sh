#!/bin/zsh -f

# Get absolute path to this script
THIS_ABS_PATH=${0:A}

# Get immediate relative info
SCRIPT_NAME=${THIS_ABS_PATH##*/}
PARENT_PATH=${THIS_ABS_PATH%/*}

# Assert we are *named what* we should be
if [[ $SCRIPT_NAME != 'set_env.sh' ]]; then
  echo "Warning: expected this script to be named \"set_env.sh\", instead it's \"$scriptName\"."
fi

# Assert we are *where* we should be
parentName=${PARENT_PATH##*/}
if [[ $parentName != 'Scripts' ]]; then
  echo "Warning: expected this script's parent directory to be \"Scripts\", instead it's \"$parentName\"."
fi


readonly SCRIPTSDIR=$PARENT_PATH
readonly PROJECTDIR=${PARENT_PATH%/Scripts}


# print -n "Sourcing ${SCRIPTSDIR/$PROJECTDIR/\$PROJECTDIR}/$SCRIPT_NAME... "


readonly DOWNLOADS=$PROJECTDIR/Downloads
readonly LOGS=$PROJECTDIR/Logs
readonly ROOT=$PROJECTDIR/Root
readonly SOURCES=$PROJECTDIR/Sources

readonly ALL_CMDS=$LOGS/commands.sh

readonly CONFIG_SUB_PATCHED=$SOURCES/config_sub/config.sub.patched

# For interacting with the TesseractBuilt Environment independent 
# of the build scripts; needed for 'test_tesseract.sh'
export PATH=$ROOT/bin:$PATH
export TESSDATA_PREFIX=$ROOT/share/tessdata
export PROMPT="(TBE) $PROMPT"


checkConfigSub() {
  # The Xcode libs depend on our hacked/patched config.sub
  if ! [ -e $CONFIG_SUB_PATCHED ]; then
    echo "$functrace ERROR file doesn't exist, $CONFIG_SUB_PATCHED"
    return 1
  fi

  return 0
}


_exec() {
  # Try to execute a command, logging itself to ALL_CMDS, and exiting
  # w/an error if there's a failure.
  local _status

  # Make sure LOGS dir is present for ALL_CMDS
  if ! [ -d "${LOGS}" ]; then
    mkdir -p "${LOGS}"
  fi

  $@  # run the command

  _status=$?
  if [ $_status -ne 0 ]; then
    echo "$functrace ERROR running $@" >&2
    return $_status
  fi

  echo $@ >>$ALL_CMDS
  return 0
}


_exec_and_log() {
  # Try to execute a step in the build process, logging its stdout and 
  # stderr.
  #
  # pkgname :: the name of the pkg being configured/installed, e.g., leptonica
  # step :: a numbered_named step, e.g., 0_curl
  # ${@:3} :: the command to exec and log (all arguments that follow pkgname and step)
  #
  # Returns non-zero code for any error during execution.
  #
  # Running:
  #
  #   _exec_and_log leptonica-1.82.0 '2_preconfig' ./autogen.sh
  #
  # will create the dir $LOGS/leptonica-1.82.0, then run `./autogen.sh` directing its 
  # errors and outputs to 2_preconfig.err and 2_preconfig.out

  local pkgname=$1
  local step=$2
  local log_out="${LOGS}/${pkgname}/${step}.out"
  local log_err="${LOGS}/${pkgname}/${step}.err"
  local _status

  if ! [ -d ${LOGS}/${pkgname} ]; then
    mkdir -p ${LOGS}/${pkgname}
  fi

  ${@:3} >$log_out 2>$log_err

  _status=$?
  if [ $_status -ne 0 ]; then
    echo 'ERROR running' ${@:3} >&2
    echo "ERROR see $log_err for more details" >&2
    return "$_status"
  fi

  echo ${@:3} >>$ALL_CMDS
  return 0
}

alias xc=_exec
alias xl=_exec_and_log

clean() {
  local files=$1

  if [ -z $files ]; then
    echo 'Already clean.'
    return 0
  fi

  # ZSH for split single lump of text, $files, into an array of lines
  filesArr=("${(@f)${files}}")

  # Loop over files, removing, then testing if the parent-dir is empty
  for file in $filesArr; do
    print -n "Deleting $file... "
    
    msg=$(rm $file 2>&1)
    _status=$?
    if [ $_status -ne 0 ]; then
      echo "ERROR $msg"
      return $_status
    fi

    print ' done.'
    
    parentDir=${file%/*}  # substitue filename with nothing
    rmdir $parentDir 2>/dev/null && echo "Deleted dir $parentDir"
  done
}

checkForXcodeLib() {
  lib=$1
  arch=$2

  [ -f $lib ] || return 1
  
  info=$(xcrun lipo -info $lib)
  
  [[ $info =~ 'Non-fat file' ]] || return 1
  [[ $info =~ $ARCH ]]          || return 1

  print "Skipped config/make/install, found valid single-arch-$ARCH lib ${lib/$ROOT/\$ROOT}"
  return 0
}

validateBuiltLib() {
  lib=$1
  arch=$2

  if ! [ -f $lib ]; then
    echo "ERROR could not find $lib"
    return 1
  fi

  info=$(xcrun lipo -info $lib)

  if ! [[ $info =~ 'Non-fat file' ]]; then
    echo "ERROR expected a single-arch (\"non-fat\") lib, found \"$info\""
    return 1
  fi

  if ! [[ $info =~ $ARCH ]]; then
    echo "ERROR expected a lib for arch $arch, found \"$info\""
    return 1
  fi

  return 0
}

verifyPlatform() {
  platform=$1

  [ -d /Applications/Xcode.app/Contents/Developer/Platforms/$PLATFORM ] && return 0
  
  echo "ERROR $platform does not exist"

  return 1
}

download() {
  local name=$1
  local url=$2
  local targz=$3

  if [ -e $DOWNLOADS/$targz ]; then
    # Replace the path-value of $PROJECTDIR w/literal '$PROJECTDIR', for brevity
    # shellcheck disable=SC2016
    local _downloads=${DOWNLOADS/$PROJECTDIR/'$PROJECTDIR'}
    echo "Skipped download, found $_downloads/$targz"
    return 0
  fi

  print -n 'Downloading...'
  xc mkdir -p $DOWNLOADS || exit 1
  xl $name '0_curl' curl -L -f $url --output $DOWNLOADS/$targz || exit 1
  print ' done.'
}


extract() {
  # Called by all build scripts to unpack a tarball
  local name=$1
  local targz=$2
  local dirname=$3

  if [ -d $SOURCES/$dirname ]; then
    # shellcheck disable=SC2016
    local _sources=${SOURCES/$PROJECTDIR/'$PROJECTDIR'}
    echo "Skipped extract of TGZ, found $_sources/$dirname"
    return 0
  fi

  print -n 'Extracting...'
  xc mkdir -p $SOURCES || exit 1
  xl $name '1_untar' tar -zxf $DOWNLOADS/$targz --directory $SOURCES || exit 1
  print ' done.'
}


print_project_env() {
  # Print out this environment's variables
  cat << EOF

Directories:
\$PROJECTDIR:  $PROJECTDIR
\$DOWNLOADS:   $DOWNLOADS 
\$ROOT:        $ROOT
\$SCRIPTSDIR:  $SCRIPTSDIR
\$SOURCES      $SOURCES

Scripts:
\$SCRIPTSDIR/Build_All.sh             clean|run all configure/build scripts
\$SCRIPTSDIR/gnu-tools/Build_All.sh   clean|run all GNU-prerequisite build scripts
\$SCRIPTSDIR/xcode-libs/Build_All.sh  clean|run all Xcode libs configure/build scripts
\$SCRIPTSDIR/test_tesseract.sh        after build, run a quick test of tesseract

Functions:
print_project_env  print this description of the project environment

EOF
}

# print 'done.'
