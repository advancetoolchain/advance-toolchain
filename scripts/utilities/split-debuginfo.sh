#!/bin/bash
#
# Copyright 2017 IBM Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Parse input parameters
while [[ $# > 0 ]]
do
  key="$1"
  case $key in
    --rpmdir)
      rpmdir="$2"
      shift
      ;;
    --dynamic)
      dynamic="$2"
      shift
      ;;
    --subpackage)
      subpackage="$2"
      shift
      ;;
    *)
      ;;
  esac
  shift
done

# Print usage instructions
usage() {
  cat << EOF
usage: $0 [options]

Options (all options must be set):
  --rpmdir        Points to the directory where the RPMs are being built.
  --dynamic       Points to the directory that contains the spec files.
  --subpackage    Selects subpackage (runtime, devel, etc.) to split.
EOF
exit 1
}

# Check if the required debugfiles.list exists.
debugfiles=${rpmdir}/BUILD/debugfiles.list
if [ ! -f ${debugfiles} ]; then
  echo "List of debug files (${debugfiles}) not found."
  usage
fi

# Check if the list of files in a subpackage exists.
regularfiles=${dynamic}/${subpackage}.list
if [ ! -f ${regularfiles} ]; then
  echo "List of files in ${subpackage} (${regularfiles}) not found."
  usage
fi

# For each file listed as a debug files (i.e.: files listed in debugfiles.list)
# check if it belongs to the subpackage being parsed (i.e.: to --subpackage).
rm -f ${rpmdir}/BUILD/debugfiles-${subpackage}.list
for item in `cat ${debugfiles} | grep -E '\.debug$'`; do
  # Get the non-debuginfo filename
  if echo $item | grep -E "\.build-id" > /dev/null ; then
    # Files inside the /opt/atx.x/lib/debug/.build-id directory are symbolic
    # links to the binary files which generated them.
    linkname=`echo ${item} | sed -e 's/\.debug//'`
    linktarget=`readlink ${rpmdir}/BUILDROOT_*/$linkname | sed -e 's/+/\\\+/g'`
    targetname=`basename ${linktarget}`
    filename=${targetname}
  else
    # Files outside the /opt/atx.x/lib/debug/.build-id dir are regular files
    # and their names are the same from the binary files which originated them.
    filename=`basename ${item} | sed -e 's/\.debug//' | sed -e 's/+/\\\+/g'`
  fi
  echo $filename
  # If the debug file belongs to a subpckage, add it to the list of debug files
  # in such subpackage.
  if grep -E "\/${filename}\"$" ${regularfiles} > /dev/null ; then

    # Devel package have python and ld files but don't have the binaries.
    if [[ ${subpackage} = "devel" ]]; then
      # The devel debug package should not include python and ld.
      if [[ ${filename} =~ "python" || ${filename} = "ld" ]]; then
        continue
      fi
    fi

    echo ${item} >> ${rpmdir}/BUILD/debugfiles-${subpackage}.list
    # For files under /opt/atx.x/lib/debug/.build-id, also add the symbolic
    # link without the '.debug' extension, because the files under
    # /opt/atx.x/lib/debug/.build-id always come in pairs.
    if echo $item | grep -E "\.build-id" > /dev/null ; then
      echo ${item} | sed -e 's/\.debug//' \
           >> ${rpmdir}/BUILD/debugfiles-${subpackage}.list
    fi
  fi
done

