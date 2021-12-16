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


# Function: isolate_files_by_pack_type()
#
# Description:
#   This function filters out files by name to be placed on the required filelist,
#   it's used to isolate runtime and development packages from a given build
#   filelist.
#
# Parameters
# - package_type: (in) a string that indicates the kind of filter to apply. It
#                 could be "all", "devel" or "runtime", filtering respectively
#                 none of the files in the list (all), only files related to
#                 development packages (devel) or only files related to runtime
#                 packages (runtime).
#
# - original_filelist: (in) a file pathname with the list of file pathnames to
#                      be filtered out
#
# - processed_filelist: (out) a file pathname with the resulting list of
#                       filtered file pathnames
#
# Ex. isolate_files_by_pack_type package_type original_filelist processed_filelist
#
# TODO: Remember that may be a potential problem with filenames with spaces in
#       the first parameter (original filelist) which will broke the process.
#
function isolate_files_by_pack_type()
{
	# Assign the parameters to local variables
	local pkg_type="${1}"
	local filelist="${2}"
	local pkg_list="${3}"

	# Check for file and include it...
	if [[ -r "${config}"/packages/groups ]]; then
		source "${config}"/packages/groups
	else
		echo "Missing essential file for build: ${config}/packages/groups"
		echo "Aborting build!"
		exit 1
	fi

	# Expand imported filters
	# NOTE: The expansion must use octal representation \040 = ' ' to avoid
	#       expansion and interpretation errors. Don't change it!
	local expanded_devel_exclude=$(printf $'\040'"-e %s" ${devel_exclude[@]})
	local expanded_devel_include=$(printf $'\040'"-e %s" ${devel_include[@]})
	local expanded_runtime_exclude=$(printf $'\040'"-e %s" ${runtime_exclude[@]})
	local expanded_runtime_include=$(printf $'\040'"-e %s" ${runtime_include[@]})

	# Perform main processing
	echo "Processing ${filelist} for ${pkg_type}..."

	# Conditionally process the file list provided
	case "${pkg_type}" in
		"all")
			sed -re '/^.*\/share\/info\/dir$/d' \
			     -e '/^.*\/share\/info\/.*$/d' ${filelist} \
				> "${pkg_list}.tmp" && \
			mv "${pkg_list}.tmp" "${pkg_list}" || \
			exit 1
			;;
		"devel")
			sed -re '/^.*\/share\/info\/dir$/d' \
			     -e '/^.*\/compat\/include\/.*$/d' \
			     ${expanded_devel_exclude} ${filelist} | \
			grep -E ${expanded_devel_include} | \
			sed "s|\(\/share\/info\/.*\.info.*\)|\1\.gz|" > "${pkg_list}.tmp" && \
			mv "${pkg_list}.tmp" "${pkg_list}" || \
			exit 1
			;;
		"develall")
			sed -r '/^.*\/share\/info\/dir$/d' ${filelist} | \
			sed "s|\(\/share\/info\/.*\.info.*\)|\1\.gz|" > "${pkg_list}.tmp" && \
			mv "${pkg_list}.tmp" "${pkg_list}" || \
			exit 1
			;;
		"runtime")
			# Notice that there is no 'runtime_include', as the
			# runtime should include all remaining files left after
			# devel removal. If this behavior change in the future,
			# just add a grep with it here (it's contents is already
			# expanded above), and make sure it's filled up on
			# CONFIG_ROOT/<at_version>/packages/groups
			sed -re '/^.*\/share\/info\/dir$/d' \
			     ${expanded_runtime_exclude} ${filelist} > "${pkg_list}.tmp" && \
			mv "${pkg_list}.tmp" "${pkg_list}" || \
			exit 1
			;;
		"runtimeall")
			sed -r '/^.*\/share\/info\/dir$/d' ${filelist} > "${pkg_list}.tmp" && \
			mv "${pkg_list}.tmp" "${pkg_list}" || \
			exit 1
			;;
		*)
			echo "Unrecognized pack type ${pkg_type}... Bailing out."
			exit 1
			;;
	esac
	# Signal end of processing
	echo "Completely process into ${pkg_list}."
}



# Function: process_filelist()
#
# Description:
#   Perform the substitution of well known path components to keep the file
#   list compatible with the rpm spec file that uses it
#
# Parameters:
# - original_filelist: (in) a file pathname containing a list of file pathnames
#                      for a given rpm package
#
# - processed_filelist: (out) a file pathname to hold the replaced file
#                       pathnames with the well known path components
#                       substituted by the RPM macros that defines them.
#                       It also generates a "${processed_list}file" with
#                       unique entries for the original_filelist.
#
# Ex. process_filelist original_filelist processed_filelist
#
function process_filelist()
{
	# Associate given parameters
	local original_list="${1}"
	local processed_list="${2}"

	# Recreate file list, abort the process if it fails
	sort -u "${original_list}" | \
	     sed -e "s|^${at_dest}/||" \
	         -e "s|^${at_dest}||" \
	         -e "s|^bin/|\%\{_bindir\}/|" \
	         -e "s|^bin64/|\%\{_bindir\}64/|" \
	         -e "s|^etc/|\%\{_prefix\}/etc/|" \
	         -e "s|^include/|\%\{_includedir\}/|" \
	         -e "s|^info/|\%\{_infodir\}/|" \
	         -e "s|^lib/|\%\{_libdir\}/|" \
	         -e "s|^lib64/|\%\{_libdir\}64/|" \
	         -e "s|^libexec/|\%\{_libexecdir\}/|" \
	         -e "s|^libexec64/|\%\{_libexecdir\}64/|" \
	         -e "s|^man/|\%\{_mandir\}/|" \
	         -e "s|^ppc/|\%\{_prefix\}/ppc/|" \
	         -e "s|^ppc64le/|\%\{_prefix\}/ppc64le/|" \
	         -e "s|^powerpc|\%\{_prefix\}/powerpc|" \
	         -e "s|^sbin/|\%\{_sbindir\}/|" \
	         -e "s|^sbin64/|\%\{_sbindir\}64/|" \
	         -e "s|^share/man/|\%\{_mandir\}/|" \
	         -e "s|^share/info/|\%\{_infodir\}/|" \
	         -e "s|^share/|\%\{_datadir\}/|" \
	         -e "s|^ssl/|\%\{_prefix\}/ssl/|" \
	         -e "s|^compat/bin/|\%\{_compatbindir\}/|" \
	         -e "s|^compat/bin64/|\%\{_compatbindir\}64/|" \
	         -e "s|^compat/etc/|\%\{_compatprefix\}/etc/|" \
	         -e "s|^compat/lib/|\%\{_compatlibdir\}/|" \
	         -e "s|^compat/lib64/|\%\{_compatlibdir\}64/|" \
	         -e "s|^compat/libexec/|\%\{_compatlibexecdir\}/|" \
	         -e "s|^compat/libexec64/|\%\{_compatlibexecdir\}64/|" \
	         -e "s|^compat/sbin/|\%\{_compatsbindir\}/|" \
	         -e "s|^compat/sbin64/|\%\{_compatsbindir\}64/|" \
	         -e "s|^compat/share/|\%\{_compatdatadir\}/|" \
	         -e 's|^\(.*\)$|\"\1\"|' >> "${processed_list}" && \
	sort -u "${original_list}" >> "${processed_list}file" || \
	exit 1
}



# Function: group_filelists_cross()
#
# Description
#   Group filelists to be used on the cross compiler package process.
#   - cross.* has the list of all files except those listed in cross-common.*,
#     which are common files.
#   - cross-runtime-extras files has a list with runtime packages.
#
# Parameters
#   - none
#
# Ex. group_filelists_cross
#
function group_filelists_cross()
{
	# Inform function execution
	echo "Begin group_filelists_cross ($@)..."
	TARGET="$1"

	rm -f "${dynamic_spec}"/cross_files.list* \
	      "${dynamic_spec}"/cross.list* \
	      "${dynamic_spec}"/cross-common.list* \
	      "${dynamic_spec}"/cross-runtime-extras.list* \
	      "${dynamic_spec}"/cross-mcore-libs.list* \
	      "${dynamic_spec}"/cross-libnxz.list*
	sort -u "${dynamic_spec}"/devel.list >> "${dynamic_spec}"/cross_files.list
	sort -u "${dynamic_spec}"/devel.listfile >> "${dynamic_spec}"/cross_files.listfile
	sort -u "${dynamic_spec}"/runtime.list >> "${dynamic_spec}"/cross_files.list
	sort -u "${dynamic_spec}"/runtime.listfile >> "${dynamic_spec}"/cross_files.listfile
	local common_regex1='^"%{_(data|include|info|man)dir}'
	local common_regex2="^${at_dest}/+(share|include)"
	egrep "${common_regex1}" "${dynamic_spec}"/cross_files.list | \
		grep -v "$TARGET" > \
		"${dynamic_spec}"/cross-common.list || \
		exit 1
	(egrep -v "${common_regex1}" "${dynamic_spec}"/cross_files.list; \
	 grep "$TARGET" "${dynamic_spec}"/cross_files.list) | sort -u > \
		"${dynamic_spec}"/cross.list.tmp && \
		mv "${dynamic_spec}"/cross.list.tmp \
		   "${dynamic_spec}"/cross.list || \
		exit 1
	egrep "${common_regex2}" "${dynamic_spec}"/cross_files.listfile | \
		grep -v "$TARGET" > \
		"${dynamic_spec}"/cross-common.listfile || \
		exit 1
	(egrep -v "${common_regex2}" "${dynamic_spec}"/cross_files.listfile; \
	 grep "$TARGET" "${dynamic_spec}"/cross_files.listfile) | sort -u > \
		"${dynamic_spec}"/cross.listfile.tmp && \
		mv "${dynamic_spec}"/cross.listfile.tmp \
		   "${dynamic_spec}"/cross.listfile || \
		exit 1
	if [[ -e "${dynamic_spec}"/toolchain_extra.list ]]; then
		sort -u "${dynamic_spec}"/toolchain_extra.list | tee \
			>(egrep "${common_regex1}" >> "${dynamic_spec}"/cross-common.list) | \
			  egrep -v "${common_regex1}" > "${dynamic_spec}"/cross-runtime-extras.list
		[[ ${?} -ne 0 ]] && exit 1
		sort -u "${dynamic_spec}"/toolchain_extra.listfile | tee \
			>(egrep "${common_regex2}" >> "${dynamic_spec}"/cross-common.listfile) | \
			  egrep -v "${common_regex2}" > "${dynamic_spec}"/cross-runtime-extras.listfile
		[[ ${?} -ne 0 ]] && exit 1
		sort -u "${dynamic_spec}"/mcore-libs.list | tee \
			>(egrep "${common_regex1}" >> "${dynamic_spec}"/cross-common.list) | \
			  egrep -v "${common_regex1}" > "${dynamic_spec}"/cross-mcore-libs.list
		[[ ${?} -ne 0 ]] && exit 1
		sort -u "${dynamic_spec}"/mcore-libs.listfile | tee \
			>(egrep "${common_regex2}" >> "${dynamic_spec}"/cross-common.listfile) | \
			  egrep -v "${common_regex2}" > "${dynamic_spec}"/cross-mcore-libs.listfile
		[[ ${?} -ne 0 ]] && exit 1
	fi

	if [[ -e "${dynamic_spec}"/libnxz.list ]]; then
		sort -u "${dynamic_spec}"/libnxz.list | tee \
			>(egrep "${common_regex1}" >> "${dynamic_spec}"/cross-common.list) | \
			  egrep -v "${common_regex1}" > "${dynamic_spec}"/cross-libnxz.list
		[[ ${?} -ne 0 ]] && exit 1
		sort -u "${dynamic_spec}"/libnxz.listfile | tee \
			>(egrep "${common_regex2}" >> "${dynamic_spec}"/cross-common.listfile) | \
			  egrep -v "${common_regex2}" > "${dynamic_spec}"/cross-libnxz.listfile
		[[ ${?} -ne 0 ]] && exit 1
	fi

	echo "Completed group_filelists_cross..."
}
