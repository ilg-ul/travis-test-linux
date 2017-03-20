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

script=$0
if [[ "${script}" != /* ]]
then
  # Make relative path absolute.
  script=$(pwd)/$0
fi

parent="$(dirname ${script})"
# echo $parent

# -----------------------------------------------------------------------------

# https://docs.travis-ci.com/user/environment-variables/#Default-Environment-Variables

# For local build, provide 
# - TRAVIS=false
# - TRAVIS_OS_NAME=osx|linux

# - TRAVIS_REPO_SLUG=<user>/<repo>

if [ "${TRAVIS}" == "true" ]
then
  work="${HOME}"
  # slug="${TRAVIS_BUILD_DIR}"
  # project_folder="${slug}/f4discovery-tests-micro-os-plus"
else
  work="${HOME}/Work/travis"
  project_folder="/Users/ilg/My Files/MacBookPro Projects/uOS/eclipse-test-projects.git/f4discovery-tests-micro-os-plus"
  # project="$(dirname ${parent})"
  # slug="$(dirname ${project_folder})"
fi

# project_name="$(basename ${project_folder})"


if [ "${TRAVIS_OS_NAME}" == "osx" ]
then

  cache="${HOME}/Library/Caches/Travis"

elif [ "${TRAVIS_OS_NAME}" == "linux" ]
then

  cache="${HOME}/.cache/travis"

fi

mkdir -p "${cache}"

# -----------------------------------------------------------------------------

function do_run()
{
  echo "\$ $@"
  "$@"
}

function do_run_quietly()
{
  echo "\$ $@ > output.log"
  "$@" > "${work}/output.log"
}

# -----------------------------------------------------------------------------

# Errors in this function will break the build.
function do_before_install() {

  echo "Before install, bring extra tools..."

  SAVED_PATH=${PATH}

  if [ "${TRAVIS}" == "true" ]
  then

    if [ "${TRAVIS_OS_NAME}" == "osx" ]
    then
      :
    elif [ "${TRAVIS_OS_NAME}" == "linux" ]
    then
      :
    fi
  
  else
    # When not running on Travis, clean play arena.
    do_run rm -rf "${work}"
  fi

  do_run npm --version

  return 0
}

# Errors in this function will break the build.
function do_before_script() {

  echo "Before starting the test, generate the projects..."

  return 0
}

# Errors in this function will break the build.
function do_script() {

  echo "The main test code; perform the tests..."

  echo
  echo "PASSED"
  return 0
}

# Errors in the following function will not break the build.

function do_after_success() {

  echo "Nothing to do after success..."
  return 0
}

function do_after_failure() {

  echo "Nothing to do after failure..."
  return 0
}

function do_deploy() {

  echo "Nothing to do to deploy..."
  return 0
}

function do_after_script() {

  echo "Nothing to do after script..."
  return 0
}

# -----------------------------------------------------------------------------

# https://docs.travis-ci.com/user/customizing-the-build/#The-Build-Lifecycle

# - OPTIONAL Install apt addons
# - OPTIONAL Install cache components
# - before_install
# - install
# - before_script
# - script
# - OPTIONAL before_cache (for cleaning up cache)
# - after_success or after_failure
# - OPTIONAL before_deploy
# - OPTIONAL deploy
# - OPTIONAL after_deploy
# - after_script

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
