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

get_nprocs () {

        # Simple method for determining number of worker threads to use.
        # Read the /proc/cpuinfo file and find the number of lines with "processor"

        local CORES_FOUND=1
        if [[ -r /proc/cpuinfo ]]; then
                CORES_FOUND=$(cat /proc/cpuinfo | grep "processor" | wc -l);
        fi
        if [[ "${CORES_FOUND}" > 0 ]]; then
                echo "${CORES_FOUND}"
        else
		# There must be at least 1 cpu, use that in case the above command failed 
        	echo "1"
        fi
}

## Function gen_gpg_pubkey
# Brief
# description
# @fn gen_gpg_pubkey <repo_path> <gnupg_path> <gpg_keyid>
# @param base repository path where the key will be saved.  If it's empty, it
#	 won't export the key.
# @param path where the gnupg keychain is located. Leave it empty to use the
#	 default directory.
# @param inform the keyid to extract the public component
# @return the file name of the extracted public key file
#
gen_gpg_pubkey () {
	local pubName PARSEME DECSINCEEPOCH HEXSINCEEPOCH FULLPUBKEY gpghome

	if [[ ${#} -ne 3 ]]; then
		return 1
	fi

	gpghome=${2:+--homedir "${2}"}

	set -e
	pubName=$(gpg ${gpghome} --list-keys --fast-list-mode ${3} | \
			  grep -e '^pub ' | sed 's/.*\/\(.*\) .*/\1/' | \
			  tr "[:upper:]" "[:lower:]")
	if [[ -z ${pubName} ]]; then
		return 1;
	fi
	PARSEME=$(gpg --fixed-list-mode --with-colons --list-keys --with-fingerprint ${pubName} | grep pub)
	DECSINCEEPOCH=$(echo "${PARSEME}" | awk -F : '{print $6 }')
	HEXSINCEEPOCH=$(printf "%x" ${DECSINCEEPOCH})
	if [[ -z "${HEXSINCEEPOCH}" ]]; then
		return 1;
	fi
	FULLPUBKEY="gpg-pubkey-${pubName}-${HEXSINCEEPOCH}"

	# Only export the key when the path is set.
	if [[ -n "${1}" ]]; then
		gpg ${gpghome} --yes --output ${1}/${FULLPUBKEY} --armor \
		    --export ${pubName}
	fi

	set +e
	echo "${FULLPUBKEY}"
}

# Return the version of the GNU program specified in $1
#
# @fn get_gnu_version <program>
# @param program Complete path to the GNU program the version is going to get
#	 extracted
get_gnu_version ()
{
	# Print the version string of a standard GNU program, e.g. 1.13.4
	${1} --version | head -n 1 | sed 's/.* \([^ ]*\)$/\1/g'
}
