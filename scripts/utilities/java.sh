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
# Find the path of Java with JIT support

# Look for a java package installed as rpm package.
find_rpm_java ()
{
	# Format of the output of RPM.
	local query_fmt="%{N}-%{V}-%{R}.%{arch}\n"
	local ibm1_java_rpm="$(rpm -qa | grep '^ibm-' | grep '\-java')"
	local ibm2_java_rpm="$(rpm -qa | grep '^java-' | grep '\-ibm-' \
			       | grep '\-devel')"
	local dist_java_rpm="$(rpm -qa | grep '^java-' | grep -v '\-ibm-' \
			       | grep '\-devel')"
	local java_rpm_pkgs="${ibm1_java_rpm} ${ibm2_java_rpm} ${dist_java_rpm}"

	# Find Java path. Give priority to the JRE downloaded from IBM website.
	for java_pkg in ${java_rpm_pkgs}; do
		# There is a bug in SLES 10 which causes rpm to
		# return 0 when a package isn't installed, but another
		# package with the same name but different architecture
		# is. In this case, rpm returns 0, but doesn't print
		# the package name.
		# As we are querying all installed devel packages, with its
		# architecture added, there is no need to perform queries
		# for both architectures independently anymore.
		result=$(rpm -q --queryformat="%{V}" ${java_pkg} | \
			 awk 'BEGIN { FS="." } \
			      { if ($1 > 1) print $1; else print $2; }')
		if [[ ${?} -eq 0 ]] && [[ -n "$(echo ${java_versions} | grep -o "${result}")" ]]; then
			java_path=$(rpm -ql \
				        --queryformat=${query_fmt} \
				        ${java_pkg} \
				    | grep "\/jvmti\.h" \
				    | sed "s|/include/jvmti\.h||")
			if [[ -n "${java_path}" ]]; then
				echo "${java_path}"
				return 0
			fi
		fi
	done

	return 1
}

# Look for a java installed using the bin package (aka InstallAnywhere).
find_bin_java ()
{
	# List of supported Java versions.
	local supported_ver="java-ppc64le-80 java-ppc64le-71"

	for version in ${supported_ver}; do
		if [[ -e "/opt/ibm/${version}/include/jvmti.h" ]]; then
			echo "/opt/ibm/${version}"
			return 0
		fi
	done

	return 1
}

case "${pack_sys}" in
	"rpm")
		find_rpm_java || find_bin_java
		;;
	"deb")
		find_bin_java
		;;
	*)
		echo "Which packaging system is \'${pack_sys}\'?"
		exit 1
esac
