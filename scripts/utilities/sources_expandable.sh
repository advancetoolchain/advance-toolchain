#! /bin/bash
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
# This file contains functions that are required for expanding functions
# referenced on package's sources files. It should be included whenever the
# expansion of these referenced functions is required.


# supported_languages()
# Summary:
#   Function to expand the supported languages list passed as a parameter
#
# Description:
#   This function receives two comma delimited list of language names as
#   parameters. This list is the supported languages to output on a readable
#   format for display on our documentation (namely the release notes file).
#
# Parameters:
#   ${1} - Comma separated list of GCC supported languages.
#
# Return
#   None.
#
function supported_languages() {
	# Define local variables
	local name
	local list
	# Iterate through the GCC supported languages
	for name in $(echo "${1}" | sed 's/,/ /g'); do
	local item=$(echo ${name} | tr '[:upper:]' '[:lower:]' | sed 's/.*/\u&/')
	[[ -n "${list}" ]] && \
		list="${list}, ${item}" || \
		list=${item}
	done
	# Provide the final output
	echo "[${list}]"
}
