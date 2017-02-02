#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# Safety settings (see https://gist.github.com/ilg-ul/383869cbb01f61a51c4d).

if [[ ! -z ${DEBUG} ]]
then
  set ${DEBUG} # Activate the expand mode if DEBUG is anything but empty.
else
  DEBUG=""
fi

set -o errexit # Exit if command failed.
set -o pipefail # Exit if pipe failed.
set -o nounset # Exit if variable not set.

# Remove the initial space and instead use '\n'.
IFS=$'\n\t'

# -----------------------------------------------------------------------------

function do_before_install() {
  echo "before_install started"

  pwd
  uname -a

  gcc --version
  which gcc
  java -version
  which java

  # cat /Users/travis/build.sh
  env
  # ls -l /usr/local/bin
  id
  whoami
  who

  echo "before_install completed"
  return 0
}

function do_before_script() {
  echo "before_script started"

  echo "before_script completed"
  return 0
}

function do_script() {
  echo "script started"

  echo "script completed"
  return 0
}

function do_after_script() {
  echo "after_script started"

  echo "after_script completed"
  return 0
}

if [ $# -gt 1 ]
then
  action=$1
  shift

  case ${action} in

  before_install)
    do_before_install "$@"
    ;;

  before_script)
    do_before_script "$@"
    ;;

  script)
    do_script "$@"
    ;;

  after_script)
    do_after_script "$@"
    ;;

  *)
    echo "Unsupported command" "${action}"" "$@"
    exit 1
    ;;
    
  esac
  exit 0
else
  echo "Missing command"
  exit 1
fi
