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

build="${HOME}/build"
slug="${build}/${TRAVIS_REPO_SLUG}"

# -----------------------------------------------------------------------------

site="${HOME}/out/${GITHUB_DEST_REPO}"

# -----------------------------------------------------------------------------

# Not available:
#   tree

function do_before_install() {

  echo "Before install, bring extra tools..."

  cd "${HOME}"

  # gem install html-proofer
  # htmlproofer --version

  return 0
}

function do_before_script() {

  echo "Before starting the test, clone the destination repo..."

  cd "${HOME}"

  git config --global user.email "${GIT_COMMIT_USER_EMAIL}"
  git config --global user.name "${GIT_COMMIT_USER_NAME}"

  git clone --branch=master https://github.com/${GITHUB_DEST_REPO}.git "${site}"

  return 0
}

function do_script() {

  echo "The main test code; perform the Jekyll build..."

  cd "${slug}"

  # Be sure the 'vendor/' folder is excluded, otherwise a strage error occurs.
  bundle exec jekyll build --destination "${site}"

  # bundle exec htmlproofer "${site}"

  return 0
}

function do_after_success() {

  echo "After success, deploy to GitHub pages..."

  if [ "${TRAVIS_BRANCH}" != "master" ]; 
  then 
    echo "Not on master branch, skip deploy."
    return 0; 
  fi

  cd "${site}"

  git add --all .
  git commit -m "Deploy to Github Pages"

  # git status

  # Must be quiet and have no output, to not reveal the key.
  git push --force --quiet "https://${GITHUB_TOKEN}@github.com/${GITHUB_DEST_REPO}" master > /dev/null 2>&1

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
