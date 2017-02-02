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
site="${HOME}/ilg-ul/test-jekyll.git"

function do_before_install() {


  return 0
}

function do_before_script() {
  cd ${HOME}
  git clone https://github.com/ilg-ul/test-jekyll.git ilg-ul/test-jekyll.git
  return 0
}

function do_script() {
  bundle exec jekyll build --destination ${site}
  bundle exec htmlproofer ${site}
  return 0
}


function do_after_success() {

  return 0
}

function do_after_failure() {

  return 0
}

function do_deploy() {

  return 0
}

function do_after_script() {

  return 0
}

# -----------------------------------------------------------------------------

if [ $# -ge 1 ]
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

  after_success)
    do_after_success "$@"
    ;;

  after_failure)
    do_after_failure "$@"
    ;;

  deploy)
    do_deploy "$@"
    ;;

  after_script)
    do_after_script "$@"
    ;;

  *)
    echo "Unsupported command" "${action}" "$@"
    exit 1
    ;;
    
  esac
  exit 0
else
  echo "Missing command"
  exit 1
fi

# -----------------------------------------------------------------------------
