#!/bin/sh
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

# Usage: sh gen_notes.sh <distro>
#	 <distro>: suse OR rhel

AT_MAJOR_VERSION="05" 
AT_MAJOR="at${AT_MAJOR_VERSION}"
AT_DEST="/opt/${AT_MAJOR}"
AT_VER_REV="1.0-0"
AT_VERSION="${AT_MAJOR}-$AT_VER_REV"

CHECK_DISTRO="$1"

if [ ${CHECK_DISTRO}  = "suse" ]; then
	AT_REPO="${AT_MAJOR}/suse/SLES_10"
else
	AT_REPO="${AT_MAJOR}/redhat/RHEL5"
fi

# Update the installation location based on the major number.
sed '/\/opt\/at00/s@/opt/at00@'$AT_DEST'@' ../../at/scripts/release_notes.at.html > rel_notes.temp

# Update the toolchain directory location as it will be on the UIUC server.
sed '/AT_DIRECTORY_PLACE_HOLDER/s@AT_DIRECTORY_PLACE_HOLDER@/toolchain/at/'$AT_REPO'@' rel_notes.temp > rel_notes2.temp

# Check the distro and place the instructions for either YaST or YUM
if [ ${CHECK_DISTRO}  = "suse" ]; then
        sed '/if_SLES10/s@<!-- if_SLES10@ @' rel_notes2.temp > rel_notes3.temp
        sed '/endif_SLES10/s@endif_SLES10 -->@ @' rel_notes3.temp > rel_notes4.temp
else
        sed '/if_RHEL5/s@<!-- if_RHEL5@ @' rel_notes2.temp > rel_notes3.temp
        sed '/endif_RHEL5/s@endif_RHEL5 -->@ @' rel_notes3.temp > rel_notes4.temp
fi

# Update the release notes' toolchain 'major number' and version.
sed '/Release Notes for the Advance Toolchain/s/Toolchain 00 Version 0\.0-0/Toolchain '$AT_MAJOR_VERSION' Version '$AT_VER_REV'/' rel_notes4.temp > release_notes.${AT_VERSION}.html

rm rel_notes.temp
rm rel_notes2.temp
rm rel_notes3.temp
rm rel_notes4.temp

