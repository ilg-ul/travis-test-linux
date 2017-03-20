#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

script=$0
if [[ "${script}" != /* ]]
then
  # Make relative path absolute.
  script=$(pwd)/$0
fi

parent="$(dirname ${script})"
# echo ${parent}

if [ ${USER} == "ilg" ]
then
  # Use a custom hoembrew with extra compilers.
  # export PATH=${HOME}/opt/homebrew-gcc/bin:${PATH}
  # export ARM_NONE_EABI_GCC5_PATH="${HOME}/opt/gcc-arm-none-eabi-5_4-2016q3/bin"
  # export ARM_NONE_EABI_GCC6_PATH="${HOME}/opt/gcc-arm-none-eabi-6_2-2016q4/bin"
  :
else
  # echo "Be sure that gcc-[56] are available."
  :
fi

bash "${parent}/run-travis.sh" --develop
