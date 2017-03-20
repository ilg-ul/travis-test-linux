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
  slug="${TRAVIS_BUILD_DIR}"
  project_folder="${slug}/f4discovery-tests-micro-os-plus"
else
  work="${HOME}/Work/travis"
  project_folder="/Users/ilg/My Files/MacBookPro Projects/uOS/eclipse-test-projects.git/f4discovery-tests-micro-os-plus"
  # project="$(dirname ${parent})"
  slug="$(dirname ${project_folder})"
fi

project_name="$(basename ${project_folder})"

# https://launchpad.net/gcc-arm-embedded
# https://developer.arm.com/open-source/gnu-toolchain/gnu-rm

use_gcc5="true"
use_gcc6="true"

if [ "${TRAVIS_OS_NAME}" == "osx" ]
then

  cache="${HOME}/Library/Caches/Travis"
  eclipse_folder="${work}/Eclipse.app" 
  eclipse="${eclipse_folder}/Contents/MacOS/eclipse" 

  p2_os="macosx"
  p2_ws="cocoa"

  if [ "${use_gcc5}" == "true" ]
  then
    # https://launchpad.net/gcc-arm-embedded/5.0/5-2016-q3-update/+download/gcc-arm-none-eabi-5_4-2016q3-20160926-mac.tar.bz2
    gcc5_release="5_4-2016q3"
    gcc5_folder="gcc-arm-none-eabi-${gcc5_release}"
    gcc5_archive_name="${gcc5_folder}-20160926-mac.tar.bz2"
    gcc5_archive_url="https://launchpad.net/gcc-arm-embedded/5.0/5-2016-q3-update/+download/${gcc5_archive_name}"
  fi

  if [ "${use_gcc6}" == "true" ]
  then
    # https://armkeil.blob.core.windows.net/developer/Files/downloads/gnu-rm/6-2016q4/gcc-arm-none-eabi-6_2-2016q4-20161216-mac.tar.bz2
    gcc6_release="6_2-2016q4"
    gcc6_folder="gcc-arm-none-eabi-${gcc6_release}"
    gcc6_archive_name="${gcc6_folder}-20161216-mac.tar.bz2"
    gcc6_archive_url="https://armkeil.blob.core.windows.net/developer/Files/downloads/gnu-rm/6-2016q4/${gcc6_archive_name}"
  fi

elif [ "${TRAVIS_OS_NAME}" == "linux" ]
then

  cache="${HOME}/.cache/travis"
  eclipse_folder="${work}/eclipse"
  eclipse="${eclipse_folder}/eclipse"

  p2_os="linux"
  p2_ws="gtk"

fi

mkdir -p "${cache}"

export work
export slug
export cache
export project

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

# $1 configuration name
function do_build()
{
  local cfg=$1

  echo
  echo Build ${cfg}
  
  local code=0

  # Temporarily disable errors, because (???); 
  # if the build fails, there will be no binary and the next test will fail.
  set +o errexit 
  do_run_quietly "${eclipse}" \
    --launcher.suppressErrors \
    -nosplash \
    -application org.eclipse.cdt.managedbuilder.core.headlessbuild \
    -data "${work}/workspace" \
    -cleanBuild "${project_name}/${cfg}" 
      
  code=$?
  echo ${code}

  set -o errexit 

  # For unknown reasons, sometimes Eclipse returns 1; ignore return code. 
  # if [ \( ${code} -eq 0 \) -a \( -f "${project_folder}/${cfg}/${cfg}.elf" \) ]
  if [ -f "${project_folder}/${cfg}/${cfg}.elf" ]
  then
    return 0
  fi

  if [ -f "${work}/output.log" ]
  then
    cat "${work}/output.log"
  fi

  echo
  echo "FAILED"

  return ${code}
}

# $1 configuration name
function do_build_run()
{
  local cfg=$1

  echo
  echo Build ${cfg}
  
  local code=0

  # Temporarily disable errors, because (???); 
  # if the build fails, the attempt to run the binary will fail anyway.
  set +o errexit 

  # Clean build a configuration.
  do_run_quietly "${eclipse}" \
    --launcher.suppressErrors \
    -nosplash \
    -application org.eclipse.cdt.managedbuilder.core.headlessbuild \
    -data "${work}/workspace" \
    -cleanBuild "${project_name}/${cfg}" 
  
  code=$?

  set -o errexit 

  if [ \( ${code} -eq 0 \) -a \( -f "${project_folder}/${cfg}/${cfg}" \) ]
  then
    echo
    echo Run ${cfg}
    set +o errexit 
    do_run_quietly "${project_folder}/${cfg}/${cfg}"
    code=$?
    set -o errexit 

    if [ ${code} -eq 0 ]
    then
      return 0
    fi
  fi

  if [ \( ${code} -ne 0 \) -a \( -f "${work}/output.log" \) ]
  then
    cat "${work}/output.log"
  fi

  if [ ${code} -ne 0 ]
  then
    echo
    echo "FAILED"
  fi

  return ${code}
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


  if [ "${use_gcc5}" == "true" ]
  then
    if [ ! -f "${cache}/${gcc5_archive_name}" ]
    then
      do_run curl -L \
        "${gcc5_archive_url}" \
        -o "${cache}/${gcc5_archive_name}"
    fi

    do_run rm -rf "${work}/${gcc5_folder}"
    mkdir -p "${work}"
    do_run tar -x -j -f "${cache}/${gcc5_archive_name}" -C "${work}"

    PATH="${work}/${gcc5_folder}/bin":"${SAVED_PATH}"
    echo "${PATH}"
    do_run arm-none-eabi-gcc --version
  fi

  if [ "${use_gcc6}" == "true" ]
  then
    if [ ! -f "${cache}/${gcc6_archive_name}" ]
    then
      do_run curl -L \
        "${gcc6_archive_url}" \
        -o "${cache}/${gcc6_archive_name}"
    fi

    do_run rm -rf "${work}/${gcc6_folder}"
    mkdir -p "${work}"
    do_run tar -x -j -f "${cache}/${gcc6_archive_name}" -C "${work}"

    PATH="${work}/${gcc6_folder}/bin":"${SAVED_PATH}"
    echo "${PATH}"
    do_run arm-none-eabi-gcc --version
  fi

  PATH=${SAVED_PATH}

  if [ "${TRAVIS_OS_NAME}" == "osx" ]
  then
    eclipse_archive_name=eclipse-cpp-mars-2-macosx-cocoa-x86_64.tar.gz
  elif [ "${TRAVIS_OS_NAME}" == "linux" ]
  then
    eclipse_archive_name=eclipse-cpp-mars-2-linux-gtk-x86_64.tar.gz
  fi

  eclipse_url="http://artfiles.org/eclipse.org//technology/epp/downloads/release/mars/2/${eclipse_archive_name}"

  if [ ! -f "${cache}/${eclipse_archive_name}" ]
  then
    do_run curl -L \
    "${eclipse_url}" \
    -o "${cache}/${eclipse_archive_name}"
  fi

  # https://github.com/gnuarmeclipse/plug-ins/releases/download/v3.2.1-201701141320/ilg.gnuarmeclipse.repository-3.2.1-201701141320.zip
  gae_version="3.2.1-201701141320"
  gae_folder="ilg.gnuarmeclipse.repository-${gae_version}"
  gae_archive_name="${gae_folder}.zip"
  gae_archive_url="https://github.com/gnuarmeclipse/plug-ins/releases/download/v${gae_version}/${gae_archive_name}"

  if [ ! -f "${cache}/${gae_archive_name}" ]
  then
    do_run curl -L \
    "${gae_archive_url}" \
    -o "${cache}/${gae_archive_name}"
  fi

  mkdir -p "${work}"
  cd "${work}"

  do_run rm -rf Eclipse.app eclipse
  do_run tar -x -z -f "${cache}/${eclipse_archive_name}"

  do_run rm -rf "${gae_folder}"
  mkdir "${gae_folder}"
  do_run unzip -q -d "${gae_folder}" "${cache}/${gae_archive_name}"

  do_run ls -lL

  # Install "GNU ARM Eclipse plug-ins" feature.

  # The p2.os, p2.ws, p2.arch might help to make the right plug-in selection.

  # Eclipse Launcher runt-time options
  # http://help.eclipse.org/mars/index.jsp?topic=%2Forg.eclipse.platform.doc.isv%2Freference%2Fmisc%2Fruntime-options.html

  # Eclipse provisioning, installation management
  # http://help.eclipse.org/mars/index.jsp?topic=%2Forg.eclipse.platform.doc.isv%2Fguide%2Fp2_director.html

  local feature_id="ilg.gnuarmeclipse.managedbuild.cross"
  local feature_group="${feature_id}.feature.group"

  do_run "${eclipse}" \
    --launcher.suppressErrors \
    -nosplash \
    -application org.eclipse.equinox.p2.director \
    -repository "file:///${work}/${gae_folder}" \
    -installIU "${feature_group}" \
    -tag InitialState \
    -destination "${eclipse_folder}/" \
    -profileProperties org.eclipse.update.install.features=true \
    -p2.os "${p2_os}" \
    -p2.ws "${p2_ws}" \
    -p2.arch x86_64 \
    -roaming 

  return 0
}

# Errors in this function will break the build.
function do_before_script() {

  echo "Before starting the test, generate the projects..."

  # Generate the required folders in the project, from downloaded xPacks. 
  cd "${project_folder}"
  do_run bash scripts/generate.sh "$@"

  # The project is now complete. Import it into the Eclipse workspace.
  do_run rm -rf "${work}/workspace"
  do_run "${eclipse}" \
    --launcher.suppressErrors \
    -nosplash \
    -application org.eclipse.cdt.managedbuilder.core.headlessbuild \
    -data "${work}/workspace" \
    -import "${project_folder}" 

  return 0
}

# Errors in this function will break the build.
function do_script() {

  echo "The main test code; perform the tests..."

  cd "${slug}"

  # Build & possibly run configurations.
  # Configurations too heavy (lots of traces) are build only.

  SAVED_PATH=${PATH}

  if [ "${use_gcc5}" == "true" ]
  then
 
    PATH="${work}/${gcc5_folder}/bin":"${SAVED_PATH}"
    echo $PATH

    do_build "test-cmsis-rtos-valid-release"
    do_build "test-cmsis-rtos-valid-debug"

    do_build "test-mutex-stress-release"
    do_build "test-mutex-stress-debug"

    do_build "test-sema-stress-release"
    do_build "test-sema-stress-debug"

    do_build "test-rtos-release"
    do_build "test-rtos-debug"

  fi

  if [ "${use_gcc6}" == "true" ]
  then
  
    PATH="${work}/${gcc6_folder}/bin":"${SAVED_PATH}"
    echo $PATH

    do_build "test-cmsis-rtos-valid-release"
    do_build "test-cmsis-rtos-valid-debug"

    do_build "test-mutex-stress-release"
    do_build "test-mutex-stress-debug"

    do_build "test-sema-stress-release"
    do_build "test-sema-stress-debug"

    do_build "test-rtos-release"
    do_build "test-rtos-debug"
  fi

  PATH=${SAVED_PATH}

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
