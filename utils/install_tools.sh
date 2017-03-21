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
# install_native <at_version>
install_native ()
{
	local version=${1}

	if [[ ${debian} == "yes" ]]; then
		sudo dpkg -i advance-toolchain-at*runtime_${version}* \
			|| return ${?}
		sudo dpkg -i advance-toolchain-at*devel_* \
			advance-toolchain-at*mcore-libs_* \
			advance-toolchain-at*perf_* || return ${?}
		sudo dpkg -i advance-toolchain-at*dbg* || return ${?}
		if [ -e advance-toolchain-golang* ]; then
			sudo dpkg -i advance-toolchain-golang* || return ${?}
		fi
	else
		sudo rpm -iv advance-toolchain-*runtime-${version}* \
			advance-toolchain-*devel* \
			advance-toolchain-*mcore* \
			advance-toolchain-*perf* || return ${?}
		if [ -e advance-toolchain-golang* ]; then
			sudo rpm -iv advance-toolchain-golang* || return ${?}
		fi
	fi
}

# Install AT cross-compiler
#
# install_cross
install_cross ()
{
	if [[ ${debian} == "yes" ]]; then
		sudo dpkg -i advance-toolchain-at*common* || return ${?}
		ls *at*.deb | egrep "64_|64le_" | xargs sudo dpkg -i \
			|| return ${?}
		sudo dpkg -i advance-toolchain-at*cross-ppc*mcore* \
			advance-toolchain-at*cross-ppc*extras* || return ${?}
	else
		sudo rpm -iv advance-toolchain-*common* || return ${?}
		sudo rpm -iv advance-toolchain-*cross-ppc* || return ${?}
	fi
}

# Install AT packages.
#
# install <files_path> <at_version>
install ()
{
	pushd ${1}
	shift

	if [[ $(uname -m) == ppc* ]]; then
		install_native ${@}
	else
		install_cross
	fi;
	ret=${?}

	popd
	return ${ret}
}

# Uninstall AT packages.
#
# uninstall <packages_list>
uninstall ()
{
	local list=${1}

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
