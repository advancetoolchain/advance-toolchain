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
# File: pkg_build_rpm.sh
#
# Description:
#   This script holds a series of functions used to build the RPM packages.
#   The process involves the isolation of package files, its classification,
#   grouping and (inter) dependency of them, as well as the generation of the
#   proper spec files for each package in the package set, and final generation
#   of the packages, ready to upload to our repository servers.
#

# Load required external functions
source "${utilities}/pkg_build_granular.sh"
source "${utilities}/pkg_build_monolithic.sh"

# Prepare the RPM build environment if if doesn't exist
declare -x rpmdir=$(mk_path "${tmp_dir}/rpmbuild" no)
declare -x rpmspecs=$(mk_path "${rpmdir}/SPECS" no)
declare -x rpmbuild=$(mk_path "${rpmdir}/BUILD" no)
declare -x rpmbuildroot=$(mk_path "${rpmdir}/BUILDROOT" no)
declare -x rpmfinal=$(mk_path "${rpmdir}/RPMS" no)

# Function: pkg_prepare_spec()
#
# Description
#   Perform the placeholders substitution, replacing the variables
#   where necessary for the final spec file generation
#
# Parameters
# - none
#
# Ex: pkg_prepare_spec
#
function pkg_prepare_spec()
{
	# Perform the appropriate requested build
	if [[ "${rpm_build_type}" == "granular" ]]; then
		#
		echo "Doing granular spec files"
		build_granular_specs
	else
		#
		echo "Doing monolithic spec files"
		build_monolithic_spec
	fi
}


# Function: pkg_build_rpms()
#
# Description
#   This function sets the required parameters to generate all the RPM packages,
#   which have a .spec file defined on ${rpmspecs}. It uses xargs to run the
#   6 rpmbuilds in parallel.
#
# Parameters
# - none
#
# Ex: pkg_build_rpms
#
function pkg_build_rpms()
{
	local at_glibc_version=$(get_package_info glibc ATSRC_PACKAGE_VER | \
				 awk 'BEGIN { FS="." }; { print $1$2 }' -)
	local at_min_power_arch="${build_load_arch/power/}"
	if [[ "${at_use_fedora_relnam}" == "yes" ]]; then
		if [[ "${at_internal}" == "none" ]]; then
			local rev_number=${at_revision_number}.1
		else
			local rev_number=${at_revision_number}.0.${at_internal}
		fi
	else
		rev_number=${at_revision_number}
	fi

	cp "${utilities}/cachemanager.service" "${rpmdir}"

	# Copy find-debuginfo.sh from the system and patch it to support
	# debuginfo under /opt.
	#
	# Typically, debug information is always placed under /usr/lib/debug on
	# rpm-based distributions. However, it is sometimes desirable to
	# install to an alternative prefix, such as /opt.
	#
	# Unfortunately, the rpm project does not provide an easy way to change
	# the installation path of the debug information. Thus, we patch
	# find-debuginfo.sh in order to be able to do so.
	local debuginfo_src="/usr/bin/find-debuginfo"
	[[ ! -e ${debuginfo_src} ]] && debuginfo_src="/usr/lib/rpm/find-debuginfo.sh"
	cp ${debuginfo_src} ${rpmdir}/find-debuginfo.sh
	sed ${rpmdir}/find-debuginfo.sh -i -e "/usr\/lib/s/\$RPM_BUILD_ROOT/\${RPM_BUILD_ROOT}/g"
	sed ${rpmdir}/find-debuginfo.sh -i -e "/RPM_BUILD_ROOT/s@/usr/lib/debug@__AT_DEST__&@"
	sed ${rpmdir}/find-debuginfo.sh -i -e "/d \".{RPM_BUILD_ROOT}\/usr\/lib\"/s@/usr/lib@__AT_DEST__&@"
	sed ${rpmdir}/find-debuginfo.sh -i -e "/\.debug/s@/usr/lib@__AT_DEST__&@g"
	sed ${rpmdir}/find-debuginfo.sh -i -e "/LISTFILE/s@/usr@__AT_DEST__&@"
	sed ${rpmdir}/find-debuginfo.sh -i -e "/find/s@usr/lib/debug@__AT_DEST__/&@"
	sed ${rpmdir}/find-debuginfo.sh -i -e "/local l/s@/usr/lib@__AT_DEST__&@"
	sed ${rpmdir}/find-debuginfo.sh -i -e "s/\/usr\/lib\/debug\/\*)/__AT_DEST__&/"
	sed ${rpmdir}/find-debuginfo.sh -i -e "/cd \".{RPM_BUILD_ROOT}\/usr\"/s@/usr@__AT_DEST__&@"
	sed ${rpmdir}/find-debuginfo.sh -i -e "/^  local id.*idfile/ireturn;"
	sed ${rpmdir}/find-debuginfo.sh -i -e "s/__AT_DEST____AT_DEST__//"

	# Fix installation path of debuginfo files:
	#   From: /opt/atx.x/usr/lib/debug
	#     To: /opt/atx.x/lib/debug
	sed ${rpmdir}/find-debuginfo.sh -i -e "s/__AT_DEST__\/usr/__AT_DEST__/g"
	sed ${rpmdir}/find-debuginfo.sh -i -e "/sepdebugcrcfix/s/ usr\/lib/ lib/"

	# Do not create .debug symlinks on RHEL. This copies the behaviour from SLES.
	sed ${rpmdir}/find-debuginfo.sh -i -e "/make a .debug symlink to that file/i#Do nothing (copied from SLES)"
	sed ${rpmdir}/find-debuginfo.sh -i -e "/make a .debug symlink to that file/,+11d"

	# Do not strip getconf
	sed ${rpmdir}/find-debuginfo.sh -i -e "/perm/s/)/& ! -path \"*getconf*\"/"

	# Do not strip libgo
	sed ${rpmdir}/find-debuginfo.sh -i -e "/perm/s/)/& ! -name \"libgo.so*\"/"

	# Do not strip ld
	sed ${rpmdir}/find-debuginfo.sh -i -e "/perm/s/)/& ! -name \"ld*.so*\"/"

	# From RHEL8, set path to call rpm scripts (debugedit, sepdebugcrcfix...)
	sed ${rpmdir}/find-debuginfo.sh -i -e "/lib_rpm_dir=/s/=.*$/=\/usr\/lib\/rpm/"

	# From RHEL9, set path to call rpm scripts (debugedit, sepdebugcrcfix...)
	sed ${rpmdir}/find-debuginfo.sh -i -e "/install_dir=/s/=.*$/=\/usr\/bin/"

	# Final step to support debuginfo under /opt.
	sed ${rpmdir}/find-debuginfo.sh -i -e "s@__AT_DEST__@${at_dest}@"

	cp "${scripts}/utilities/split-debuginfo.sh" "${rpmdir}"
	local count=0
	while IFS= read -d $'\0' -r specfile; do
		count=$(( count + 1 ))
		local activerpmbuild=$(mk_path "${rpmdir}/BUILDROOT_${count}" no)
		echo --buildroot "${activerpmbuild}" \
		     --clean \
		     "${specfile}"
	done < <(find "${rpmspecs}" -name '*.spec' -print0) | \
		xargs -t -n 4 \
		     rpmbuild -bb \
			      --define="at_work ${dynamic_spec}" \
			      --define="_topdir ${rpmdir}" \
			      --define="_rpmdir ${rpmdir}" \
			      --define="_arch ${build_arch}" \
			      --define="_build_arch ${build_arch}" \
			      --define="_prefix ${at_dest}" \
			      --define="at_major ${at_major_internal}" \
			      --define="at_major_version ${at_major_version}" \
			      --define="at_revision_number ${rev_number}" \
			      --define="at_glibc_ver ${at_glibc_version}" \
			      --define="_min_power_arch ${at_min_power_arch}" \
			      --define="at_ver_rev_internal ${at_ver_rev_internal}" \
			      --define="at_ver_alternative ${at_ver_rev_internal//./}" \
			      --define="at_dir_name ${at_dir_name}" \
			      --define="_tmpdir ${tmp_dir}" \
			      --define="_golang /usr/local/go/" \
			      --define="target ${target}" \
			      --target="${host_arch}-linux"
	if [[ ${?} -ne 0 ]]; then
		echo "Error generating rpm packages."
		exit 1
	fi
}


# Function: pkg_move_rpms()
#
# Description
#   This function moves the generated RPM packages to its final place, and also
#   generates the sources.sh with information for ....
#
# Parameters:
# - none
#
# Ex: pkg_move_rpms
#
function pkg_move_rpms()
{
	# Clean up the destination and update it
	[[ -d "${rpms}/${host_arch}" ]] && \
		rm -rf "${rpms}/${host_arch}"
	mv "${rpmdir}/${host_arch}" "${rpms}"

	# Set the values required for the sources.sh script generation
	if [[ "${cross_build}" == "yes" ]]; then
		if [[ "${build_exclusive_cross}" ]]; then
			local dist_all="yes"
		else
			local dist_all="no"
		fi
		local sign_repo="${at_sign_repo_cross}"
		local sign_pkgs="${at_sign_pkgs_cross}"
	else
		local dist_all="yes"
		local sign_repo="${at_sign_repo}"
		local sign_pkgs="${at_sign_pkgs}"
	fi

	# Generate the sources.sh script
	sed -e "s@__AT_BASE__@${at_base}@g" \
	    -e "s@__AT_LOGDIR__@${logs}@g" \
	    -e "s@__AT_NAME__@${at_name}@g" \
	    -e "s@__AT_MAJOR_VERSION__@${at_major_version}@g" \
	    -e "s@__AT_REVISION_NUMBER__@${at_revision_number}@g" \
	    -e "s@__DIST_ALL__@${dist_all}@g" \
	    -e "s@__SIGN_REPO__@${sign_repo}@g" \
	    -e "s@__SIGN_PKGS__@${sign_pkgs}@g" \
	    -e "s@__GPG_KEYID__@${at_gpg_keyid}@g" \
	    -e "s@__GPG_KEYIDC__@${at_gpg_keyidc}@g" \
	    -e "s@__GPG_KEYIDL__@${at_gpg_keyidl}@g" \
	    -e "s@__GPG_KEYID_REPO__@${at_gpg_repo_keyid}@g" \
	    -e "s@__GPG_KEYID_REPOC__@${at_gpg_repo_keyidc}@g" \
	    -e "s@__GPG_KEYID_REPOL__@${at_gpg_repo_keyidl}@g" \
	    -e "s@__AT_COMPAT_DISTROS__@${at_compat_distros}@g" \
	    -e "s@__AT_SUPPORTED_DISTROS__@${at_supported_distros}@g" \
	    -e "s@__DISTRO_PROVIDER__@$(echo "${distro_id}" | cut -d '-' -f 1)@g" \
	    -e "s@__DISTRO_VERSION__@$(echo "${distro_id}" | cut -d '-' -f 2)@g" \
	    -e "s@__AT_SRC_TAR_FILE__@${src_tar_file}@g" \
	    -e "s@__AT_RELNOT_FILE__@${relnot_file}@g" \
	    -e "s@__AT_REPOCMD_OPTS__@${at_repocmd_opts}@g" \
	    -e "s@__RPM_BUILD_DIR__@${rpms}/${host_arch}@g" \
	        "${skeletons}/sources_skel.sh" > \
	        "${rpms}/sources.sh" && \
		chmod +x "${rpms}/sources.sh" || \
		exit 1
}


#
#
#
#
#

# First step to build... Prepare the RPMs specfiles
# This must be done after preparing all the filelist contents used by the
# specs.
pkg_prepare_spec

# With the RPMs specfiles ready, perform the build in a parallel way
pkg_build_rpms

# And finally, move them to the final place
pkg_move_rpms
