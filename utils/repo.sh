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

# Script used to manipulate AT repository mirroring

# List of files/directories/links deleted in the last build
RM_FILES=${RM_FILES:-./delete-files}
# List of files/directories/links added or modified in the last build
NEW_FILES=${NEW_FILES:-./new-files}

# Don't run this script as root
# Run it as a user of the toolchain group'
if [[ "$(whoami)" == "root" ]]; then
	echo "Never run this script as root!" >&2
	exit 1
fi

usage ()
{
	cat <<EOF
usage:  ${0} <command> <parameters of the command>

Hint: 	repo1 is the place where the AT team work.
	repo2 is the place where the OSS team work.

List of commands:
    clone <repo1> <repo2>	Clone (or update) repo2 into repo1.

    diff <repo1> <repo2>	List the differences to make repo2 a clone of
				repo1. Creates the lists of files required by
				push.

    pack			Create the tarball ticket.tar.gz which is ready
				for ticket submission

    push <repo1> <repo2>	Push the differences from repo1 to repo2.
				Requires the output of diff in order to work.

    set_perms <repo1>		Set the correct permission and ownership of
				files and directories of repo1.
				This command is restricted to /export/repo/ for
				safety reasons.

    verify <repo1>		Verify the integrity of an external repository.
				This is normally used in order to verify the
				contents of the staging area (ftp).
				<repo1> is the base path of the repository.
EOF
}

# Verify if NEW_FILES and RM_FILES are available.  Fail if they aren't'.
check_files ()
{
	if [[ ! -e ${NEW_FILES} || ! -e ${RM_FILES} ]]; then
		cat >&2 <<EOF
Can't find files ${NEW_FILES} and ${RM_FILES}.
Have you already run the following command?
	${0} diff ${1} ${2}
EOF
		exit 1
	fi
}

set_perms ()
{
	local OWNER="root:toolchain"
	local DPERMS="775" # Directory permissions
	local FPERMS="664" # File permissions

	if [[ "${1}" != "/export/repo/" ]]; then
		echo "I refuse to change permissions of a directory other than \
/export/repo/" >&2
		exit 1
	fi

	set -e
	echo "Setting ownership recursively for \"${1}\""
	sudo chown -R ${OWNER} "${1}"

	for DIR in $(find "${1}" -type d -print); do
		sudo chmod ${DPERMS} "${DIR}"
	done

	for FILE in $(find "${1}" -type f -print); do
		sudo chmod ${FPERMS} "${FILE}"
	done
	set +e
}

clone ()
{
	rsync -crlz --delete-after -v "${2}" "${1}"
	# Make sure everything has the correct permissions
	set_perms "${1}"
}

diff ()
{
	# Fix permissions when running as a toolchain user
	# This is done automatically in order to make sure everything is fine
	# prior to open the ticket
	groups | grep "toolchain" > /dev/null
	if [[ ${?} -eq 0 ]]; then
		set_perms "${1}"
	fi

	# As the AT team has read only access to the rsync server, it's
	# necessary' to invert the order of the parameters (using --dry-run
	# doesn't help'), which inverts the logic of the comparison.
	# So, if rsync returns a new file it means this file was removed by
	# the last build. All the other files are considered new or modified
	# files.
	RM_REGEX='^[<>c][fdL]\+\+\+\+\+\+\+\+\+'
	rsync -crl --delete -ni ${2} ${1} | tee files
	egrep -v ${RM_REGEX} files | awk '{ print $2 }' | sort \
		> ${NEW_FILES}
	awk "/${RM_REGEX}/ {print \"/\" \$2}" files | sort > ${RM_FILES}
	rm files

	if [[ -n "${1}" ]]; then
		create_checksum_file "${1}"
	else
		touch MD5SUMS
	fi
}

push ()
{
	check_files
	rsync -crlzv --files-from=${NEW_FILES} ${1} ${2}

	# Manually remove the files
	prevdir=$(pwd)
	set -x
	pushd ${2} > /dev/null
	echo "Removing the following files..."
	cat ${prevdir}/${RM_FILES}
	cat ${prevdir}/${RM_FILES} | sed 's/^/\./g' | xargs rm -rfv
	popd > /dev/null
	set +x
}

# Create a tarball with NEW_FILES and RM_FILES.  This tarball is used by the
# OSS team as an input.
pack ()
{
	if [[ ! -e ${NEW_FILES} || ! -e ${RM_FILES} ]]; then
		cat >&2 <<EOF
Can't find files ${NEW_FILES} and ${RM_FILES}.
Have you already run the following command?
	${0} diff ${1} ${2}
EOF
	fi

	set -e
	mkdir ticket/
	cp "${NEW_FILES}" "${RM_FILES}" "${0}" ticket/
	tar -czf ticket.tar.gz ticket/
	rm -rf ticket/
	set +e
}

# Create a MD5SUMS file to be used as an input for verify ().
create_checksum_file ()
{
	check_files

	local dir=$(pwd)

	echo "Creating checksums..."
	set -e
	pushd ${1} > /dev/null

	newf_l=""
	# Create the MD5SUMS for files only.
	for newf in $(cat ${dir}/${NEW_FILES}); do
		if [[ -f ${newf} ]]; then
			newf_l="${newf_l} ${newf}"
		fi
	done
	if [[ -n "${newf_l}" ]]; then
		md5sum ${newf_l} > ${dir}/MD5SUMS
	fi

	popd > /dev/null
	set +e
}

# Verify the integrity of the new files in a remote repository and confirm if
# files have been properly removed
verify ()
{
	check_files

	if [[ ! -e MD5SUMS ]]; then
		cat >&2 <<EOF
Can't find file MD5SUMS.
Have you already run the following command?
	${0} diff ${1} ${2}
EOF
		exit 1
	fi

	# Get the staging area path
	local st_area=${1}
	local err=0

	# Test if ${st_area} is valid
	if ! wget -q -O /dev/null ${st_area}/; then
		echo "Invalid staging area."
		echo "Is ${st_area} correct?"
		exit 1
	fi

	echo "Checking if files have been properly removed..."
	local msg=""
	for file in $(cat ${RM_FILES}); do
		# Force to use FTP actime mode because
		# software.linux.ibm.com has a very low limit of simultaneous
		# connections (5 connections/host) and because the server
		# is not closing the connections fast enough.  So, if this loop
		# has 6 iterations, the server starts to drop connections.
		msg=$(wget --no-passive-ftp -nv -O /dev/null \
			"${st_area}/${file}" 2>&1)
		if [[ ${?} -eq 0 ]]; then
			echo "File ${st_area}/${file} is still available"
			err=1
		elif ! echo ${msg} | grep "No such" > /dev/null; then
			echo "Failed to verify ${st_area}/${file}: ${msg}"
			echo " Aborting..."
			exit 1
		fi
	done

	mkdir -p base/
	echo "Downloading new files..."
	for file in $(cat ${NEW_FILES}); do
		# Need to create the directory structure for each file in order
		# to guarantee MD5SUMS will work.
		if ! mkdir -p base/$(dirname ${file}); then
			echo "Error: failed to create directory base/$(dirname ${file})"
			return 1
		fi
		# Avoid downloading directories.
		if [[ "${file:${#file}-1}" != "/" ]] && \
		   ! wget -q -O base/${file} ${st_area}/${file}; then
			echo "Error: failed to download ${st_area}/${file}"
			err=1
		fi
		# Create a progress bar
		echo -n "."
	done
	# End the progress bar
	echo

	if [[ "${err}" -ne "0" ]]; then
		return ${err}
	fi

	echo "Verifying integrity..."
	set -e
	pushd base/ > /dev/null
	md5sum --quiet -c ../MD5SUMS
	popd > /dev/null
	set +e

	if [[ "${err}" -eq "0" ]]; then
		echo "The repository passed the integrity test!"
	fi

	return ${err}
}

case "${1}" in
	clone|diff|push)
		if [[ ${#} -ne 3 ]]; then
			usage >&2
			exit 1
		fi
		${1} "${2}" "${3}"
		;;
	set_perms|verify)
		if [[ ${#} -ne 2 ]]; then
			usage >&2
			exit 1
		fi
		${1} "${2}" || exit ${?}
		;;
	pack)
		if [[ ${#} -ne 1 ]]; then
			usage >&2
			exit 1
		fi
		${1}
		;;
	*)
		usage >&2
		exit 1
		;;
esac
