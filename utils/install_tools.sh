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
# Install tools
# This script offers a set of functions to help install and test AT packages.
#
# Commands:
# 	install uninstall collect list testsuite

# Install AT packages on PowerPC
#
# install_native <at_version> <command>
install_native ()
{
	local version=${1}

	# Allowing AT next to be installed. AT next packages don't have 'next'
	# in their name but a version number.
	[[ "${version}" == "next" ]] && version=[0-9]
	if [[ ${debian} == "yes" ]]; then
		sudo dpkg -i advance-toolchain-at*runtime_${version}* \
			|| return ${?}
		sudo dpkg -i advance-toolchain-at*devel_* \
			advance-toolchain-at*mcore-libs_* \
			advance-toolchain-at*perf_* || return ${?}
		if [ -e advance-toolchain-at*libnxz_* ]; then
			sudo dpkg -i advance-toolchain-at*libnxz_* || return ${?}
		fi
		sudo dpkg -i advance-toolchain-at*dbg* || return ${?}
		if [ -e advance-toolchain-golang* ]; then
			sudo dpkg -i advance-toolchain-golang* || return ${?}
		fi
	else
		sudo rpm -${2}v advance-toolchain-*runtime-${version}* \
			advance-toolchain-*runtime-debuginfo* \
			advance-toolchain-*devel* \
			advance-toolchain-*mcore* \
			advance-toolchain-*perf* || return ${?}
		if [ -e advance-toolchain-golang* ]; then
			sudo rpm -${2}v advance-toolchain-golang* || return ${?}
		fi
		if [ -e advance-toolchain-*libnxz-${version}* ]; then
			sudo rpm -${2}v advance-toolchain-*libnxz* || return ${?}
		fi
		if [ -e advance-toolchain-*-release* ]; then
			sudo rpm -${2}v advance-toolchain-*-release* || return ${?}
		fi
	fi
}

# Install AT cross-compiler
#
# install_cross <command>
install_cross ()
{
	if [[ ${debian} == "yes" ]]; then
		sudo dpkg -i advance-toolchain-at*common* || return ${?}
		ls *at*.deb | egrep "64_|64le_" | xargs sudo dpkg -i \
			|| return ${?}
		sudo dpkg -i advance-toolchain-at*cross-ppc*mcore* \
			advance-toolchain-at*cross-ppc*extras* || return ${?}
		if [ -e advance-toolchain-at*cross-ppc*libnxz* ]; then
			sudo dpkg -i advance-toolchain-at*cross-ppc*libnxz* || return ${?}
		fi
	else
		sudo rpm -${1}v advance-toolchain-*common* || return ${?}
		sudo rpm -${1}v advance-toolchain-*cross-ppc* || return ${?}
	fi
}

# Install AT packages.
#
# install <files_path> <at_version> <command>
install ()
{
	pushd ${1}
	shift

	if [[ $(uname -m) == ppc* ]]; then
		install_native ${1} ${2}
	else
		install_cross ${2}
	fi;
	ret=${?}

	popd
	return ${ret}
}

# Install last AT version on PowerPC
#
# install_last_native <at_version>
install_last_native ()
{
	local version=${1}

	if [[ ${debian} == "yes" ]]; then
		sudo apt-get install -y \
		   advance-toolchain-at${version}-runtime \
		   advance-toolchain-at${version}-runtime-dbg \
		   advance-toolchain-at${version}-devel* \
		   advance-toolchain-at${version}-mcore-libs* \
		   advance-toolchain-at${version}-perf* \
		   || return ${?}
		if [ -e advance-toolchain-at${version}-libnxz* ]; then
			sudo dpkg -i advance-toolchain-at${version}-libnxz* || return ${?}
		fi
	else
		local os=$(cat /etc/os-release | grep "^ID=" | cut -d '"' -f2)
		if [[ ${os} == "sles" ]]; then
			sudo zypper install -y \
			   advance-toolchain-at${version}-runtime \
			   advance-toolchain-at${version}-runtime-debuginfo \
			   advance-toolchain-at${version}-devel* \
			   advance-toolchain-at${version}-mcore-libs* \
			   advance-toolchain-at${version}-perf* \
			   || return ${?}
			if [ -e advance-toolchain-at${version}-libnxz* ]; then
				sudo zypper install -y advance-toolchain-at${version}-libnxz* || return ${?}
			fi
		else
			sudo yum install -y \
			   advance-toolchain-at${version}-runtime \
			   advance-toolchain-at${version}-runtime-debuginfo \
			   advance-toolchain-at${version}-devel* \
			   advance-toolchain-at${version}-mcore-libs* \
			   advance-toolchain-at${version}-perf* \
			   || return ${?}
			if [ -e advance-toolchain-at${version}-libnxz* ]; then
				sudo yum install -y advance-toolchain-at${version}-libnxz* || return ${?}
			fi
		fi
	fi
}

# Install last cross-compiler AT version
#
# install_last_cross <at_version>
install_last_cross ()
{
	local version=${1}

	if [[ ${debian} == "yes" ]]; then
		sudo apt-get install -y \
		   advance-toolchain-at${version}-cross* \
		   || return ${?}
	else
		local os=$(cat /etc/os-release | grep "^ID=" | cut -d '"' -f2)
		if [[ ${os} == "sles" ]]; then
			sudo zypper install -y \
			   advance-toolchain-at${version}-cross* \
			   || return ${?}
		else
			sudo yum install -y \
			   advance-toolchain-at${version}-cross* \
			   || return ${?}
		fi
	fi
}

# Install last AT version
#
# install_last <at_version>
install_last ()
{
	if [[ $(uname -m) == ppc* ]]; then
		install_last_native ${1}
	else
		install_last_cross ${1}
	fi;
	ret=${?}
}

# Update AT packages
#
# update <files_path> <at_version> <output_list>
update ()
{
	local files=${1}
	local version=${2}
	local list=${3}

	# There is no update with internal releases.
	if [[ -z $(ls ${files} | grep -E "\-rc|alpha|beta") ]]; then
		install_last ${version}
		install ${files} ${version} U
		list ${list}
	else
		echo "Skipping: internal release."
		touch ${list}
	fi
}

# Uninstall AT packages.
#
# uninstall <packages_list>
uninstall ()
{
	local list=${1}

	if [[ ! -s ${list} ]]; then
		echo "Nothing to uninstall."
		exit
	fi

	if [[ ${debian} == "yes" ]]; then
		sudo dpkg -P $(cat ${list})
	else
		sudo rpm -ev $(cat ${list})
	fi
}

# Collect FVTR logs
#
# collect
collect ()
{
	mkdir -p artifacts/
	find fvtr/ -name '*.log' -exec tar vzcf artifacts/fvtr_logs.tgz {} +
}

# List AT installed packages
#
# list <output_file>
list ()
{
	local list=${1}

	if [[ $(uname -m) == ppc* ]]; then
		# Native.
		local package="runtime"
	else
		# Cross-compiler.
		local package="common"
	fi;

	if [[ ${debian} == "yes" ]]; then
		sudo dpkg --list | grep "advance-toolchain" \
		  | grep -v ${package} | awk '{print $2}' > ${list}
		sudo dpkg --list | grep "advance-toolchain.*${package}" \
		  | awk '{print $2}'>> ${list}
	else
		sudo rpm -qa  | grep "advance-toolchain" | grep -v ${package} \
		  > ${list}
		sudo rpm -qa  | grep "advance-toolchain.*${package}" \
		  >> ${list}
	fi
}

# Run FVTR to test it.
#
# testsuite <config_file>
testsuite ()
{
	local config=${1}

	# Set the environment.
	if [[ $(uname -m) == ppc* ]]; then
		pushd "$HOME/cpu2006/"
		source shrc
		popd
		export DHRY_TEST_DIR="$HOME/dhrystone/"
	fi

	cd fvtr
	bash fvtr.sh -f ${config}
}

if type dpkg 2> /dev/null; then
	debian="yes"
else
	debian="no"
fi

command=${1}
shift
${command} ${@}

exit
