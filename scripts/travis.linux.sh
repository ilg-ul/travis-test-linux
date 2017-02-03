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

site="${HOME}/${GITHUB_DEST_REPO}"

# -----------------------------------------------------------------------------

# Not available:
#   tree

function do_before_install() {

  cd "${HOME}"
  # tree
  ls -lL "${slug}"

  # gem install html-proofer
  # htmlproofer --version

  # bundle update

  return 0
}

function do_before_script() {

  cd "${HOME}"
  ls -lL "${slug}"

  git config --global user.email "ilg@livius.net"
  git config --global user.name "Liviu Ionescu (Travis CI)"

  git clone --branch=master https://github.com/${GITHUB_DEST_REPO}.git ${GITHUB_DEST_REPO}

  return 0
}

function do_script() {

  cd "${slug}"
  ls -lL

  bundle exec jekyll build --destination ${site}
  # bundle exec htmlproofer ${site}

  cd "${site}"

  git add --all .
  git commit -m "Deploy to Github Pages"

  git status

  git push --force --quiet "https://${GITHUB_TOKEN}@github.com/${GITHUB_DEST_REPO}" master

  if [ "${TRAVIS_BRANCH}" != "master" ]; then exit 0; fi

  return 0
}


function do_after_success() {

  cd "${site}"

  git add --all .
  git commit -m "Deploy to Github Pages"

  git status

  git push --force --quiet "https://${GITHUB_TOKEN}@$github.com/${GITHUB_DEST_REPO}" master

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
