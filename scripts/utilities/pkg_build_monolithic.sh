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

# Function: monolithic_filelists()
#
# Description
#   This function groups the isolated build filelists from package builds into
#   individual single group filelists to be used on the rpm build process.
#   Please note that they do so for monolithic package builds only.
#
# Parameters
# - none
#
# Ex. monolithic_filelists
#
function monolithic_filelists()
{
	local GROUP PACK
	local groups=$(find "${dynamic_spec}"/. -mindepth 1 -type d -printf '%f ')

	# Clean up final lists (from previous build)
	for GROUP in ${groups}; do
		rm -fv "${dynamic_spec}/${GROUP}/${GROUP}"*.list
	done
	# Remove processed files (from previous build)
	rm -fv "${dynamic_spec}"/*.list{,file}{,.orig}

	# Process group files list
	for GROUP in ${groups}; do
		echo "Preparing file list for ${GROUP}..."
		pushd "${dynamic_spec}/${GROUP}"
		if [[ "${GROUP}" == *toolchain || \
		     ("${GROUP}" == "toolchain_extra" && \
		      "${cross_build}" == "no") ]]; then
			echo "Isolate normal file lists..."
			local normallist=$(find . -name '*.filelist' -print | \
					sed -r '/^.+_compat.*$/d')
			echo "Isolate compat file lists..."
			local compatlist=$(find . -name '*.filelist' -print | \
					sed -r '/^.+_compat.*$/!d')
			echo "Segregate devel and runtime files for normal lists..."
			isolate_files_by_pack_type devel "${normallist}" "${GROUP}_devel.list"
			isolate_files_by_pack_type runtime "${normallist}" "${GROUP}_runtime.list"
			echo "Process normal devel and runtime generated file lists..."
			process_filelist "${GROUP}_devel.list" "${dynamic_spec}/devel.list"
			process_filelist "${GROUP}_runtime.list" "${dynamic_spec}/runtime.list"
			if [[ -n "${compatlist}" ]]; then
				echo "Segregate all files for compat lists..."
				isolate_files_by_pack_type all "${compatlist}" "${GROUP}_compat.list"
				echo "Process compat all generated file lists..."
				process_filelist "${GROUP}_compat.list" "${dynamic_spec}/compat.list"
			fi
		else
			case "${GROUP}" in
				"devel" | "runtime")
					local filter="${GROUP}all"
					;;
				*)
					local filter="all"
					;;
			esac;
			local filelist="$(find . -name '*.filelist' -print)"
			isolate_files_by_pack_type "${filter}" "${filelist}" "${GROUP}_${filter}.list"
			process_filelist "${GROUP}_${filter}.list" "${dynamic_spec}/${GROUP}.list"
		fi
		rm -rf "${temp-list}"
		popd
	done

	# Order all the processed files lists
	packages=$(find "${dynamic_spec}/." -maxdepth 1 -type f -name '*.list' -printf '%f ')
	for PACK in ${packages}; do
		sort -u "${dynamic_spec}/${PACK}" > "${dynamic_spec}/${PACK}.tmp" && \
		mv "${dynamic_spec}/${PACK}" "${dynamic_spec}/${PACK}.orig" && \
		mv "${dynamic_spec}/${PACK}.tmp" "${dynamic_spec}/${PACK}" || \
		exit 1
		sort -u "${dynamic_spec}/${PACK}file" > "${dynamic_spec}/${PACK}file.tmp" && \
		mv "${dynamic_spec}/${PACK}file" "${dynamic_spec}/${PACK}file.orig" && \
		mv "${dynamic_spec}/${PACK}file.tmp" "${dynamic_spec}/${PACK}file" || \
		exit 1
	done

	# Group files lists on cross builds
	if [[ "${cross_build}" == "yes" ]]; then
		group_filelists_cross "$@"
	fi
}



# Function: build_monolithic_spec()
#
# Description
# - This function assembles the final spec file for the monolithic rpm package
#   build. It assemble the spec file for native and cross builds. It also
#   fills the dependency requirements
#
# Parameters
# - none
#
# Ex: build_monolithic_spec
#
function build_monolithic_spec()
{
	echo "Signaling for cross on cross packages."
	cross=$([[ "${cross_build}" == "yes" ]] && echo "-cross" || echo "")
	echo "Signaling the build arch for the package spec."
	bld_arch=$([[ "${cross_build}" == "yes" ]] && echo "-${build_arch}" || echo "")
	echo "Set the packager/vendor as well as build arch and cross flag on spec file..."
	sed -e "$([[ -n ${build_rpm_packager} ]] && \
		echo "s|__RPM_PACKAGER__|${build_rpm_packager}|g" || \
		echo "/__RPM_PACKAGER__/d")" \
	    -e "$([[ -n ${build_rpm_vendor} ]] && \
		echo "s|__RPM_VENDOR__|${build_rpm_vendor}|g" || \
		echo "/__RPM_VENDOR__/d")" \
	    -e "s|__TARGET_ARCH__|${bld_arch}|g" \
	    -e "s|__CROSS__|${cross}|g" \
	    "${config_spec}/main.spec" > \
		"${rpmspecs}/advance-toolchain.spec"

	if [[ -z ${cross} ]]; then
		echo "For native package builds only:"
		if [[ "${build_ignore_compat}" != "yes" ]]; then
			echo "Prepare the base compat spec whenever needed."
			cat "${rpmspecs}/advance-toolchain.spec" \
			    "${config_spec}/monolithic_compat.spec" > \
				"${rpmspecs}/advance-toolchain_compat.spec"
		fi
		if [[ "${build_ignore_at_compat}" != "yes" ]]; then
			echo "Prepare the base at-compat spec whenever needed."
			cat "${rpmspecs}/advance-toolchain.spec" \
			    "${config_spec}/monolithic_at-compat.spec" | \
				sed -e "s|__AT_OLD_VER__|${build_old_at_version}|g" \
				    -e "s|__AT_OLD_DEST__|${build_old_at_install}|g" > \
					"${rpmspecs}/advance-toolchain_at-compat.spec"
			echo "Fill actual/old AT versions/destination for at-compat."
			sed -e "s|__AT_VER__|${at_major_version}|g" \
			    -e "s|__AT_OVER__|${build_old_at_version}|g" \
			    -e "s|__AT_DEST__|${at_dest}|g" \
			    -e "s|__AT_ODEST__|${build_old_at_install}|g" \
			    "${skeletons}/at_compat_runtime_skel.sh" > \
				"${rpmdir}/${at_major_internal}-runtime-at${build_old_at_version}-compat"
			echo "Remove from spec requires entry if empty, for at-compat."
			grep -vE '^Requires:[ \t]*$' \
			    "${rpmspecs}/advance-toolchain_at-compat.spec" > \
			    "${rpmspecs}/advance-toolchain_at-compat.spec.tmp" && \
				mv "${rpmspecs}/advance-toolchain_at-compat.spec.tmp" \
				   "${rpmspecs}/advance-toolchain_at-compat.spec" || exit 1
		fi

		if [[ "${build_arch}" == "ppc64le" \
		      && -e "${config_spec}/monolithic_golang.spec" ]]; then
			echo "Prepare the golang spec."
			cat "${config_spec}/monolithic_golang.spec" > \
			    "${rpmspecs}/advance-toolchain_golang.spec"
		fi

		echo "Continue to prepare the base spec file."
		cat "${config_spec}/monolithic.spec" >> \
			"${rpmspecs}/advance-toolchain.spec"

		for group in "${dynamic_spec}"/*.listfile; do
			echo "For each list of files, find their dependencies."
			dep_list=$(find_dependencies "${group}" | tr '\n' ' ')
			if [[ ${?} -ne 0 ]]; then
				exit 1
			fi
			echo "Set package name and its dependency list."
			pkg_name=$(basename "${group}" | sed -r 's/\.listfile$//g')
			pkg_deps="${dep_list// /, }"
			if [[ "${pkg_name}" == "compat" ]]; then
				echo "Fill the above info on compat spec file."
				sed "s|__COMPAT_REQ__|${pkg_deps}|g" \
				    "${rpmspecs}/advance-toolchain_compat.spec" > \
				    "${rpmspecs}/advance-toolchain_compat.spec.tmp" && \
					mv "${rpmspecs}/advance-toolchain_compat.spec.tmp" \
					   "${rpmspecs}/advance-toolchain_compat.spec" || exit 1
			else
				echo "Fill the same info on normal spec file."
				sed "s|__$(echo "${pkg_name}" | tr '[:lower:]' '[:upper:]')_REQ__|${pkg_deps}|g" \
				    "${rpmspecs}/advance-toolchain.spec" > \
				    "${rpmspecs}/advance-toolchain.spec.tmp" && \
					mv "${rpmspecs}/advance-toolchain.spec.tmp" \
					   "${rpmspecs}/advance-toolchain.spec" || exit 1
			fi
		done

		if [[ -f ${rpmspecs}/advance-toolchain_compat.spec ]]; then
			echo "Remove from spec requires entry if empty, for compat."
			grep -vE '^Requires:[ \t]*$' \
			     "${rpmspecs}/advance-toolchain_compat.spec" > \
			     "${rpmspecs}/advance-toolchain_compat.spec.tmp" && \
				mv "${rpmspecs}/advance-toolchain_compat.spec.tmp" \
				   "${rpmspecs}/advance-toolchain_compat.spec" || exit 1
		fi

		if [[ "$(echo "${distro_id}" | cut -d '-' -f 1)" == "suse" && -e "${config_spec}/release.spec" ]]; then
		        echo "Prepare the release spec (SUSE only)."
		        sed -e "$([[ -n ${build_rpm_vendor} ]] && \
				echo "s|__RPM_VENDOR__|${build_rpm_vendor}|g" || \
				echo "/__RPM_VENDOR__/d")" \
			    -e "s|__AT_END_OF_LIFE__|${at_end_of_life}|g" \
			    -e "s|__AT_END_OF_LIFE_ESCAPED__|$(echo "${at_end_of_life}" | sed "s/-/%2D/g")|g" \
			    -e "s|__TARGET_ARCH__|${build_arch}|g" \
			    -e "s|__DISTRO_VERSION__|$(echo "${distro_id}" | cut -d '-' -f 2)|g" \
			    "${config_spec}/release.spec" > \
				"${rpmspecs}/advance-toolchain-release.spec"
		fi
	else
		echo "For cross package builds:"
		sed -e "s|__CROSS__|${cross}|g" "${config_spec}/monolithic_cross.spec" \
			>> "${rpmspecs}/advance-toolchain.spec"
		echo "Find base cross dependencies."
		dep_list=$(find_dependencies "${dynamic_spec}/cross_files.listfile" | tr '\n' ' ')
		if [[ ${?} -ne 0 ]]; then
			exit 1
		fi
		echo "Set the base cross dependency list."
		pkg_deps="${dep_list// /, }"
		echo "Set more cross package info on spec file."
		dest_cross_rel=$(echo ${dest_cross} | \
		                 sed -r -e "s|${at_dest}/*||g" \
		                        -e 's|//*|/|g' \
		                        -e 's|(.*)/$|\1|g')
		sed -e "s|__CROSS_DEPS_PLACE_HOLDER__|${pkg_deps}|g" \
		    -e "s|__DEST_CROSS__|${dest_cross}|g" \
		    -e "s|__DEST_CROSS_REL__|${dest_cross_rel}|g" \
		    "${rpmspecs}/advance-toolchain.spec" > \
		    "${rpmspecs}/advance-toolchain.spec.tmp" && \
			mv "${rpmspecs}/advance-toolchain.spec.tmp" \
			   "${rpmspecs}/advance-toolchain.spec" || exit 1

		for group in "${dynamic_spec}"/*.listfile; do
			echo "For each package, look for its dependencies."
			dep_list=$(find_dependencies "${group}" | tr '\n' ' ')
			pkg_deps=${dep_list// /, }
			pkg_name=$(basename "${group}" | sed -r 's/\.listfile$//g')
			if [[ "${pkg_name}" == "mcore-libs" ]]; then
				sed "s|__$(echo "${pkg_name}" | tr '[:lower:]' '[:upper:]')_REQ__|${pkg_deps}|g" \
				    "${rpmspecs}/advance-toolchain.spec" > \
				    "${rpmspecs}/advance-toolchain.spec.tmp" && \
					mv "${rpmspecs}/advance-toolchain.spec.tmp" \
					   "${rpmspecs}/advance-toolchain.spec" || exit 1
			fi
		done
	fi

	grep -vE '^Requires:[ \t]*$' "${rpmspecs}/advance-toolchain.spec" > \
	     "${rpmspecs}/advance-toolchain.spec.tmp" && \
		mv "${rpmspecs}/advance-toolchain.spec.tmp" \
		   "${rpmspecs}/advance-toolchain.spec" || exit 1
}
