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
#
#
#
#
#
#
#

# Load required external common functions
source "${utilities}/pkg_build_functions.sh"
source "${utilities}/pkg_build_filefilters.sh"

## TODO: Complete rewrite of granular RPM packaging process (granular_filelists)
#
# Function: granular_filelists()
#
# Description
#   Combine the filelists from a given root package defining a standard
#   shell variable ${spec_filelist}
#
# Ex. granular_filelists
#
function granular_filelists()
{
	local stage_list
	unset stages
	for FILE in ${CONFIG}/packages/${PACKAGE}/stage*; do
		stages="${stages} $(basename "${FILE}" | sed 's/^stage//' | cut -f 1 -d '_')"
	done
	stage_list="{$(echo "${stages#${stages%%[![:space:]]*}}" | \
			tr ' ' '\n' | nl | sort -u -k2 | sort -n | cut -f2 | \
			tr '\n' ' ' | sed 's/ *$//g' | sed 's/^ *//g' | \
			tr ' ' ',')}"
	eval "ls ${RPMSPEC_ROOT}/${PACKAGE}${archs}_${stages}.filelist" > \
		"${LOGS}/_build_rpm-${PACKAGE}-01_combine_filelists.log"
	sort -u "$(eval "ls ${RPMSPEC_ROOT}/${PACKAGE}${archs}_${stages}.filelist")" | > \
		"${RPMSPEC_ROOT}/${PACKAGE}_rpm.filelist"
	unset "${!ATSRC_PACKAGE_*}"
	echo "Nothing here yet, unless the ${stage_list}..."
}



## TODO: Complete rewrite of granular RPM spec creation process (build_granular_specs)
#
# Function: build_granular_specs()
#
# Description
#   ...
#
# Parameters
# -
#
# Ex: build_granular_specs
#
function build_granular_specs() {
    echo "Nothing yet..."
}


