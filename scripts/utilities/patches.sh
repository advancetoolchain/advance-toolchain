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
# Define functions to download patches.

# Compare the checksum of the patches.  Returns 0 in case they match or 1
# otherwise.
checksum_match ()
{
	if [[ ${#} -ne 2 ]]; then
		echo "Function checksum_match expects 2 parameters."
		return 1
	fi

	local chksum=$(md5sum ${1} | awk '{print $1}')
	if [[ "${chksum}" == "${2}" ]]; then
		return 0
	else
		return 1
	fi
}


# Wrapper around wget.
# Automatically retry the download in case of failure.
# If the failure was caused by SSL errors, retry with --no-check-certificate.
# It accepts the same parameters of wget.
at_wget ()
{
	local ret=1
	# Number of tries
	local tries=10
	# Temporary log file to identify SSL certificate issues.
	local tmp_log=$(mktemp --tmpdir=${TEMP_INSTALL})

	local i=0
	while [[ ${ret} -ne 0 && ${i} -lt ${tries} ]]; do
		# Wait 30 seconds before trying again.
		[[ ${i} -gt 0 ]] && sleep 30

		wget ${wget_parms} ${@} 2>&1 | tee ${tmp_log}
		ret=${?}

		# This is workaround as some versions of wget doesn't correctly
		# return exit code 5 upon SSL errors.
		if grep -e '--no-check-certificate' ${tmp_log}; then
			wget ${wget_parms} --no-check-certificate ${@}
			ret=${?}
		fi
		i=$(expr ${i} + 1)
	done

	rm -f ${tmp_log}
	return ${ret}
}


# Download a patch if necessary and verify its checksum.
# Parameters:
#    $1 - URL of the patch.
#    $2 - Checksum of the file (using md5sum for now).
# Optional parameters:
#    $3 - File name of the patch.
at_get_patch ()
{
	if [ ${#} -ne 2 -a ${#} -ne 3 ]; then
		echo "Function at_get_patch expects 2 or 3 parameters."
		return 1
	fi

	local url=${1}
	local chksum=${2}
	local fname=$(basename ${url})

	# Set alternative filename if optional argument given
	if [ ${#} -ge 3 ]; then
		fname=${3}
	fi

	local fpath=$(pwd)/${chksum}/${fname}

	# If the patch doesn't exist or is corrupted, download it again.
	if [ ! -e ${fpath} ] || ! checksum_match ${fpath} ${chksum}; then
		mkdir -p ${chksum}
		echo "Downloading ${url}"
		if ! at_wget -O ${fpath} ${url}; then
			echo "Failed to download from ${url}"
			return 1
		fi

		# Verify.
		if ! checksum_match ${fpath} ${chksum}; then
			echo "md5sum of ${url} didn't match."
			return 1
		fi
	else
		echo "Patch is already available: ${fname}"
	fi


	# Add to the copy queue (to be copied after the rsync).
	echo ${fpath} >> ${AT_TEMP_INSTALL}/$(basename $(pwd))-copy-queue
}


# Download a patch, if necessary, trim it and verify its checksum.
# Parameters:
#    $1 - URL of the patch.
#    $2 - File name of the patch.
#    $3 - Number of lines of the patch.
#    $4 - Checksum of the file (using md5sum for now).
at_get_patch_and_trim ()
{
	if [[ ${#} -ne 4 ]]; then
		echo "Function at_get_patch_and_trim expects 3 parameters."
		return 1
	fi

	local url=${1}
	local fname=${2}
	local lines=${3}
	local chksum=${4}

	local fpath=$(pwd)/${chksum}/${fname}

	# If the patch doesn't exist or is corrupted, download it again.
	if [ ! -e ${fpath} ] || ! checksum_match ${fpath} ${chksum}; then
		mkdir -p ${chksum}
		echo "Downloading ${url}"
		if ! at_wget -O ${fpath}.tmp ${url}; then
			echo "Failed to download from ${url}"
			return 1
		fi

		# Ensure file is clear before starting to trim.
		rm -f ${fpath}

		# Beginning of the patch.
		local start=""
		local count=0
		# Treat the entire lines, including whitespace.
		IFS_SAVE=${IFS}
		IFS=
		while read -r line; do
			if [[ -z ${start} ]]; then
				start=$(echo "${line}" | \
					sed -n '/^diff/p;/^Index/p;/^--- /p')
				if [[ ! -z ${start} ]]; then
					count=$(( count + 1 ))
					echo "${line}" >> ${fpath}
					continue
				else
					continue
				fi
			else
				count=$(( count + 1 ))
				echo "${line}" >> ${fpath}
			fi
			if [[ ${count} -eq ${lines} ]]; then
				break
			fi
		done < ${fpath}.tmp
		# Return 'read' to the previous behavior.
		IFS=${IFS_SAVE}
		rm ${fpath}.tmp

		# Fix the characters messed by HTML.
		sed -i -e 's/&gt;/>/g' -e 's/&amp;/\&/g' -e 's/&lt;/</g' \
		    -e 's/&gt;/>/g' -e 's/&quot;/"/g' ${fpath}

		# Verify.
		if ! checksum_match ${fpath} ${chksum}; then
			echo "md5sum of ${url} didn't match."
			return 1
		fi
	else
		echo "Patch is already available: ${fname}"
	fi

	# Add to the copy queue (to be copied after the rsync).
	echo ${fpath} >> ${AT_TEMP_INSTALL}/$(basename $(pwd))-copy-queue
}

# Clone or update a git repo if necessary and verify its checksum.
# Parameters:
#    $1 - URL of the repository.
#    $2 - Name of the repository.
#    $3 - Commit ID.
at_git_pull ()
{
	if [[ ${#} -ne  3 ]]; then
		echo "Function at_git_pull expects 3 parameters."
		return 1
	fi

	local url=${1}
	local fname=${2}
	local commit=${3}

	local fpath=$(pwd)/${fname}

	# Check if the repository already exist.
	if [ ! -e ${fpath} ] ; then
		git clone ${url} ${fname}
		pushd ${fpath}
		git checkout ${commit}
		popd
	else
		# If the repository exist, check if it has the correct commit.
		pushd ${fpath}
		local chksum=$(git log -1 --pretty="%h")
		if [[ ${chksum} != ${commit} ]] ; then
			git pull origin master
			git checkout ${commit}
		else
			echo "${fname} is already available."
		fi
		popd
	fi

	# Add to the copy queue (to be copied after the rsync).
	echo "-r ${fpath}/*" >> ${AT_TEMP_INSTALL}/$(basename $(pwd))-copy-queue
}
