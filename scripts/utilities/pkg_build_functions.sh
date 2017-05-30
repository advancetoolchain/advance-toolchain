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
# Description:
#   This file has a set of common functions used by the RPM package build
#   system.
#
#
#
#
#
#


# Name: shopt_push()
#
# Description:
#   This function saves on a stack the given shell option for later restore
#
# Parameters:
#   - option to be saved
#
# Return:
#   Nothing
#
function shopt_push()
{
	# Guarantee the existence of the shopt stack
	if [[ -z ${SHOPT_OPTIONS_STACK} ]]; then
		declare -agx SHOPT_OPTIONS_STACK
	fi

	# Set the option to be saved
	local option=${1}
	# Find the current option setting
	local setting=$(shopt -p | grep "${option}" | cut -d ' ' -f 2)

	# Save the current setting on shopt stack
	SHOPT_OPTIONS_STACK=("${SHOPT_OPTIONS_STACK[@]}" "${setting} ${option}")
}


# Name: shopt_restore()
#
# Description:
#   This function restores the saved shell option status
#
# Parameters:
#   None
#
# Return:
#   Nothing
#
function shopt_restore()
{
	# Check for existence of shopt stack
	if [[ -n "${SHOPT_OPTIONS_STACK[@]}" ]]; then
		# Set it back
		shopt ${SHOPT_OPTIONS_STACK[@]:(-1)}
		# Remove the topmost entry of the stack
		unset SHOPT_OPTIONS_STACK[${#SHOPT_OPTIONS_STACK[@]}-1]
	else
		echo "No shopt stack to restore from!"
	fi
}


# Name: shopt_set()
#
# Description:
#   This function changes a shell option, but first, saves the current option
#   state
#
# Parameters:
#   - option to be changed
#   - status of the option to be changed (on/off)
#
# Return:
#   Nothing
#
# TODO: implement better error handling situation
function shopt_set()
{
	# Set the option given
	local option=${1}
	# Set required status
	if [[ "${2}" == "on" ]]; then
		local status="-s"
	else
		local status="-u"
	fi
	# Request a push of the current active value
	shopt_push "${option}"
	# Set the value of the given bash option
	shopt "${status}" "${option}"
}


# Function: mk_path()
#
# Description:
#   This function creates (if needed) a given path, or if required, clean it if
#   already exists. If the path is out of bounds (the process can't write in
#   it), it fails miserably.
#
# Parameters:
#   - pathname to create/clean
#   - flag to clean it or now (if it already exists)
#
# Return:
#   A string with the name of the created/existing path
#
function mk_path()
{
	# Clean up the path provided
	local mkpath="$(echo "${1}" | sed 's|//*|/|g')"
	local recreate="${2}"

	if [[ -n ${mkpath} ]]; then
		# Did it not exist or is writable ?
		if [[ (-w ${mkpath}) || (! -e ${mkpath}) ]]; then
			# Check if recreation is required
			if [[ "${recreate}" == "yes" ]]; then
				# If so, remove it...
				rm -rf "${mkpath}"
			fi
			# (Re)create it
			mkdir -p "${mkpath}"
		# If not, did it exist (and isn't writable)
		elif [[ -e ${mkpath} ]]; then
			# It exist but you haven't permission to create it
			echo "You can't access this path: ${mkpath}. Aborting."
			exit 1
		else
			# Create it otherwise
			mkdir -p "${mkpath}"
		fi
		# Return the path created
		echo "${mkpath}"
	fi
}


# Function: get_package_info()
#
# Description
#   This function collects the required information from the specified package
#   sources definition to be used by another (usually dependent) package.
#
# Parameters
# - pkg_name: (in) the package name to look for the information
# - pkg_var:  (in) the package variable to collect its content
#
# Ex. get_package_info glibc ATSRC_VERSION
#
function get_package_info()
{
	# Capture the input parameters
	local pkg_name="${1}"
	local pkg_variable="${2}"

	if [[ -d "${config}/packages/${pkg_name}" ]]; then
		source "${config}/packages/${pkg_name}/sources"
		if [[ -n ${!pkg_variable} ]]; then
			echo "${!pkg_variable}"
		else
		    echo "Undefined"
		fi
		unset ${!ATSRC_PACKAGE_*}
	else
		echo "Error"
		exit 1
	fi
}


# Function: find_dependencies()
#
# Description
#   Find the executable files (including libraries) and check their dependencies
#   adding them to the standard shell variable ${spec_deps} used on the final
#   spec file build.
#
# Parameters
# - original_filelist: (in) a file pathname with the list of file pathnames to
#                      check (if its an ELF binary) its dependencies
#
# Ex. find_dependencies original_filelist
#
function find_dependencies()
{
	# Begin to look for dependencies
	local tmp_file \
	      ignored \
	      ldd_path \
	      scan_files \
	      file_info \
	      readelf_path \
	      wordsize \
	      suffix

	# Create a temporary file
	tmp_file=$(mktemp)
	# Set tool for linked libraries verification
	if [[ "${cross_build}" == "yes" ]]; then
		ldd_path=$(which ldd)
	else
		ldd_path=${at_dest}/bin/ldd
	fi
	# Get list of files other than libraries provided
	scan_files=$(grep -vE 'ld-.*\.so' "${1}")
	for file in ${scan_files}; do
		# For each file, check if it's usable
		if [[ ! -x ${file} ]] || [[ ! -r ${file} ]]; then
			continue
		fi
		# Collect selected file info
		file_info=$(file "${file}")
		# Continue only if its a dynamically linked executable
		echo "${file_info}" | grep "dynamically linked" &> /dev/null
		if [[ ${?} -ne 0 ]]; then
			continue
		fi
		# On cross builds, check if dynamically linked executable is PPC
		if [[ "${cross_build}" == "yes" ]]; then
			readelf_path=$(which readelf)
			${readelf_path} -h "${file}" | grep "PowerPC" &> /dev/null
			if [[ ${?} -eq 0 ]]; then
				continue
			fi
		fi
		# Check the bit size of the dynamically linked executable
		wordsize=$(echo "${file_info}" | sed -e 's/^.*ELF //g' -e 's/-bit.*$//')
		if [[ ${wordsize} -eq 32 ]]; then
			suffix=
		elif [[ ${wordsize} -eq 64 ]]; then
			suffix="()(64bit)"
		else
			# TODO: I'm not sure about the effect of this echo, work
			#       on it later.
			echo "Can't recognize ${file} word size" 1>&2
			exit 1
		fi
		# Check the dynamically linked executable for AT prefix
		ignored=$( ${ldd_path} "${file}" | grep "${at_dest}" | \
			awk "{ print \$1 }" )
		if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
			echo "Failed to ldd file ${file}" 1>&2
			exit 1
		fi
		# Get the dependencies
		objdump -p "${file}" | grep "NEEDED" | grep -v "${ignored}" | \
			awk "{ print \$2 \"${suffix}\" }" >> ${tmp_file}
		if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
			echo "Failed to objdump file ${file}" 1>&2
			exit 1
		fi
	done
	sort -u "${tmp_file}"
	# Remove the temporary file
	rm -f "${tmp_file}" &> /dev/null
	# Completed the look for dependencies
}
