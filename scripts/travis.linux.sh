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

# https://docs.travis-ci.com/user/environment-variables/#Default-Environment-Variables

export build="${HOME}/build"
export slug="${build}/${TRAVIS_REPO_SLUG}"

# -----------------------------------------------------------------------------

export site="${HOME}/out/${GITHUB_DEST_REPO}"
export doxy="${build}${GITHUB_DOXY_REPO}"

# -----------------------------------------------------------------------------

function do_run()
{
  echo "\$ $@"
  "$@"
}

# -----------------------------------------------------------------------------

# Not available:
#   tree

# Errors in this function will break the build.
function do_before_install() {

  echo "Before install, bring extra tools..."

  # do_run cat /etc/apt/sources.list

  cd "${HOME}"

  # do_run gem install html-proofer
  # do_run htmlproofer --version

  # do_run doxygen --version

  # do_run sudo add-apt-repository -y ppa:clearpath-robotics/docs
  # do_run sudo apt-get -y -q update
  # do_run sudo apt-get -y install doxygen

  # http://packages.ubuntu.com/trusty-updates/

  # libclang needed by doxygen 
  do_run sudo apt-get -y install -t trusty-backports libclang1-3.8

  mkdir -p ${HOME}/downloads

  # https://launchpad.net/ubuntu/+source/doxygen
  
  doxy_deb=doxygen_1.8.11-3_amd64.deb
  do_run curl -L --silent https://launchpad.net/ubuntu/+archive/primary/+files/${doxy_deb} -o ${HOME}/downloads/${doxy_deb}

  do_run sudo dpkg -i ${HOME}/downloads/${doxy_deb}

  do_run doxygen --version
  return 0
}

# Errors in this function will break the build.
function do_before_script() {

  echo "Before starting the test, clone the destination repo..."

  cd "${HOME}"

  do_run git config --global user.email "${GIT_COMMIT_USER_EMAIL}"
  do_run git config --global user.name "${GIT_COMMIT_USER_NAME}"

  # Bring destination repository. Perhaps --depth=2 would help.
  do_run git clone --branch=master https://github.com/${GITHUB_DEST_REPO}.git "${site}"

  # Bring in the µOS++ sources, for the Doxygen input.
  do_run git clone --branch=xpack https://github.com/${GITHUB_DOXY_REPO}.git "${doxy}"

  return 0
}

# Errors in this function will break the build.
function do_script() {

  echo "The main test code; perform the Jekyll build..."

  cd "${slug}"

  # Be sure the 'vendor/' folder is excluded, 
  # otherwise a strage error occurs.
  do_run bundle exec jekyll build --destination "${site}"

  do_run ls -lL "${site}"

  # Validate images and links (internal & external).
  # do_run bundle exec htmlproofer \
  # --url-ignore="https://jekyllrb.com,https://www.keithcirkel.co.uk/how-to-use-npm-as-a-build-tool/" \
  # "${site}"

  # ---------------------------------------------------------------------------
  # The deployment code is present here not in after_success, 
  # to break the build if not successful.


  if [ "${TRAVIS_BRANCH}" != "master" ]
  then 
    echo "Not on master branch, skip deploy."
    return 0; 
  fi

  cd "${site}"
  is_dirty=`git status --porcelain`
  # Should detect new, modified, removed files.
  if [ -z "${is_dirty}" ]
  then
    echo "No changes to the output on this push; skip deploy."
    exit 0
  fi

  cd "${doxy}/doxygen"

  export DOXYGEN_OUTPUT_DIRECTORY="${HOME}/out/reference"
  export DOXYGEN_STRIP_FROM_PATH="${doxy}"

  do_run doxygen config-travis.doxyfile
  do_run ls -l "${DOXYGEN_OUTPUT_DIRECTORY}"

  cd "${site}"
  do_run git diff

  do_run git add --all .
  do_run git commit -m "Travis CI Deploy of ${TRAVIS_COMMIT}" 
 
  # git status

  # Temporarily disable deployment, due to 
  # - inconsistent results from jekyll-last-modified-at.
  return 0

  echo "Deploy to GitHub pages..."

  # Must be quiet and have no output, to not reveal the key.
  git push --force --quiet "https://${GITHUB_TOKEN}@github.com/${GITHUB_DEST_REPO}" master > /dev/null 2>&1

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
