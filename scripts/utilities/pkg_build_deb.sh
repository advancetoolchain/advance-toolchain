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

# Create a debhelper compatible directory in order to build deb packages and
# build them.

set -e
# Debhelper parent dir
base=${debs}/debhelper
# Configuration files
deb_d=${base}/debian

# Remove all information about runtime-compat in order to not create it.
remove_compat ()
{
	echo "Disabling runtime-compat package."
	# Package information in a control file starts with "Package:" and
	# stop at the end of the paragraph (in the next blank line).
	sed -ie "/Package: advance-toolchain[^\n]\+runtime-compat/,/^$/d" ${deb_d}/control
}

# Clean the debhelper tree
rm -rf "${deb_d}"
mkdir -p ${deb_d}

at_version=$(echo ${at_full_ver} | cut -d"." -f 1)
at_full_ver_deb_format=$(echo ${at_full_ver} | tr "-" ".")

# Set systemd cache manager directories.
if [[ "${use_systemd}" == "yes" ]]; then
	cp "${utilities}/cachemanager.service" ${debh_root}/monolithic/
	systemd_unit=$(pkg-config --variable=systemdsystemunitdir systemd)
	systemd_preset=$(pkg-config --variable=systemdsystempresetdir systemd)
fi

# Set the directory with the raw configuration files
if [[ "${cross_build}" == "yes" ]]; then
	spec=${debh_root}/monolithic_cross
else
	spec=${debh_root}/monolithic
fi

# Remove previously created deb files
rm -f ${debs}/*.deb
# Clear a previous build
if [[ -e debian/rules ]]; then
	pushd ${base} > /dev/null
	fakeroot make -f debian/rules clean
	popd > /dev/null
fi

# Copy configuration files
pushd ${spec} > /dev/null
go_dest="/usr/local/go"
for f in *; do
	echo "Setting up ${deb_d}/${f}"
	sed -e "s/__AT_DEST__/${at_dest//\//\\/}/g" \
	    -e "s/__AT_FULL_VER__/${at_full_ver_deb_format}/g" \
	    -e "s/__AT_MAJOR_INTERNAL__/${at_major_internal}/g" \
	    -e "s/__DATE__/$(date -R)/g" \
	    -e "s/__DEST_CROSS__/${dest_cross//\//\\/}/g" \
	    -e "s/__TARGET__/${target}/g" \
	    -e "s/__BUILD_ARCH__/-${build_arch}/g" \
	    -e "s/__AT_VER_REV_INTERNAL__/${at_ver_rev_internal}/g" \
	    -e "s/__AT_VER_ALTERNATIVE__/${at_ver_rev_internal//./}/g" \
	    -e "s/__AT_DIR_NAME__/${at_dir_name}/g" \
	    -e "s/__TMP_DIR__/${tmp_dir//\//\\/}/g" \
	    -e "s/__GO_DEST__/${go_dest//\//\\/}/g" \
	    -e "s/__SYSTEMD_UNIT__/${systemd_unit//\//\\/}/g" \
	    -e "s/__SYSTEMD_PRESET__/${systemd_preset//\//\\/}/g" \
	    -e "s/__USE_SYSTEMD__/${use_systemd}/g" \
	    ${f} > ${deb_d}/${f}
done
[[ -s ${deb_d}/changelog ]] && sed -i '/^#/d' ${deb_d}/changelog
popd > /dev/null

# Copy dh_strip from the system and patch it to support debuginfo under /opt
#
# Typically, debug information is always placed under /usr/lib/debug on
# debian-based distributions. However, it is sometimes desirable to install to
# an alternative prefix, such as /opt.
#
# Unfortunately, the debhelper project does not provide an easy way to change
# the installation path of the debug information. Thus, we patch dh_strip in
# order to be able to do so.
if [[ "${cross_build}" != "yes" ]]; then
	pushd ${deb_d} > /dev/null
	cp /usr/bin/dh_strip .

	# For some distros, make sure we also use 'strip' and 'objcopy' from
	# the binutils we just built instead of the ones from the system. This
	# specific change will only be applied to distros with a reference to
	# __AT_BIN__ in their *dh_change_dest.patch file.
	patch -p1 < <(sed -e "s/__AT_BIN__/${at_dest//\//\\/}\/bin\//g" \
			${at_supported_distros}_dh_change_dest.patch)

	popd > /dev/null
fi

[[ "${cross_build}" != "yes" && "${build_ignore_compat}" == "yes" ]] && remove_compat

# Test if this is a cross compiler with support for cross-common package.
if egrep "^Package:.*cross-common" ${deb_d}/control; then
	has_cross_common=yes
else
	has_cross_common=no
fi

# Make adjustments for each package
for pkg in $(awk '/^Package:/ { print $2 }' ${deb_d}/control | grep -v dbg); do
	# Get if this is a runtime, devel, compat, etc.
	apkg=$(echo ${pkg} \
	       | sed -e 's/^.*'${at_major_internal}'-//g' \
		     -e 's/^.*golang.*$/golang/g')

	echo "Preparing files to package ${pkg}"

	# Rename script files (postrm, postinst, etc.)
	for file in ${deb_d}/${apkg}.*; do
		# Ignore this package when it doesn't have script files.
		[[ ! -e ${file} ]] && continue
		suffix=$(basename ${file} | sed "s/${apkg}\.//")
		mv ${file} ${deb_d}/${pkg}.${suffix}
	done

	# Copy the list of files
	case "${apkg}" in
		"perf")
			# For an unknown reason, the list of files of the perf
			# package is called profile.listfile.
			apkg="profile"
			;;
		"runtime-compat")
			apkg="compat"
			;;
		cross-ppc*)
			# In AT versions that support the cross-common package,
			# the list of files for the main cross package is
			# called cross.listfile.
			# In AT versions that support other packages, we need
			# to remove the arch in the name to match the list of
			# files.
			if [[ "${has_cross_common}" == "yes" ]]; then
				apkg=$(echo ${apkg} \
				       | sed 's/-'${build_arch}'//g')
			else
				apkg="cross_files"
			fi
			;;
		golang)
			# Golang package already has the right apkg value.
			;;
		*)
			# The version-agnostic packages are dummy and don't
			# provide any contents, just dependency entries.
			[[ -n "${pkg##*${at_major_internal}*}" ]] && continue 2
			;;
	esac

	rm -f ${deb_d}/${pkg}.install

	if [[ ! -e ${dynamic_spec}/${apkg}.listfile ]]; then
		# Something is really wrong because the list of files is
		# missing.
		echo "Could not find ${dynamic_spec}/${apkg}.listfile"
		exit 1
	fi

	# Don't list directories because dh_install understands that all their
	# files should be copied to the package unless it's an empty directory.
	prevIFS="${IFS}"
	IFS=$'\n'
	for item in $(sort -u ${dynamic_spec}/${apkg}.listfile); do
		if [[ -L "${item}" \
		      || ! -d "${item}" \
		      || -z "$(ls ${item})" ]]; then
			# DEB packages don't support white spaces in file paths
			# so, it's necessary to change them by a wildcard (i.e.
			# ?) in order to use them.
			echo "${item}" \
				| sed -e 's/^\///g' \
				      -e 's| |\?|g' \
				>> ${deb_d}/${pkg}.install
		fi
	done
	IFS="${prevIFS}"

	# Hack for files under scripts/.
	# TODO: We should really think way to deal with these files on RPM and
	# DEB.
	if [[ "${cross_build}" != "yes" ]]; then
		# find_dependencies.sh is for RPM systems.
		rm -f ${at_dest}/scripts/find_dependencies.sh
		# We don't need this file because the copyright file already
		# includes the same text.
		rm -f ${at_dest}/scripts/LICENSE
		rm -f ${at_dest}/scripts/createldhuge-1.0.sh
		rm -f ${at_dest}/scripts/restoreld.sh

		# TLE helper is enabled for AT9 and beyond.
		addtlehelper="yes"
	{
		case "${apkg}" in
			"devel")
				echo "${at_dest}/scripts/at-create-ibmcmp-cfg.sh"
				;;
			"runtime")
				[[ "${use_systemd}" != "yes" ]] && \
					echo "/etc/cron.d/${at_ver_rev_internal//./}_ldconfig"
				[[ ${addtlehelper} == "yes" ]] && \
					echo "${at_dest}/scripts/tle_on.sh"
				;;
		esac
	} | sed -e 's/^\///g' >> ${deb_d}/${pkg}.install
	fi
done

# Make adjustments for debuginfo packages
for pkg in $(awk '/^Package:/ { print $2 }' ${deb_d}/control | grep dbg); do
	apkg=$(echo ${pkg} \
	       | sed 's/^.*'${at_major_internal}'-//g')

	echo "Preparing files to package ${apkg}"

	# Rename script files (postrm, postinst, etc.)
	for file in ${deb_d}/${apkg}.*; do
		# Ignore this package when it doesn't have script files.
		[[ ! -e ${file} ]] && continue
		suffix=$(basename ${file} | sed "s/${apkg}\.//")
		mv ${file} ${deb_d}/${pkg}.${suffix}
	done
done

# Create the deb file
pushd ${base} > /dev/null
DEB_BUILD_OPTIONS="parallel=4" \
	fakeroot make -f debian/rules binary
popd > /dev/null

set +e
