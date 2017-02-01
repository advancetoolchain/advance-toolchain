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

# Identify the name of the target based on the word size.
# The word size is usually provided by the target name and stored at
# AT_BIT_SIZE.
find_build_target() {
	if [[ -n "${1}" ]]; then
		if [[ "${1}" == "32" ]]; then
			echo "${target32}"
		elif [[ "${1}" == "64" ]]; then
			echo "${target64}"
		fi
	fi
}

find_build_libdir() {
	if [[ -n "${1}" ]]; then
		echo "lib${1%32}"
	fi
}


find_build_bindir() {
	if [[ -n "${1}" ]]; then

		# When 32 or 64 targets are possible, select the
		# dir name based on the size for the current build
		if [[ -n "${target32}" && -n "${target64}" ]]; then
			echo "bin${1%32}"

		# If only a 32 or 64 bit target is possible then use bin
		else
			echo "bin"
		fi
	fi
}

find_build_sbindir() {
	if [[ -n "${1}" ]]; then
		# When 32 or 64 targets are possible select the dir name
		# based on the size
		if [[ -n "${target32}" && -n "${target64}" ]]; then
			echo "sbin${1%32}"

		# If only one target is possible, use sbin
		else
			echo "sbin"
		fi
	fi
}

find_build_libexecdir() {
	if [[ -n "${1}" ]]; then
		echo "libexec${1%32}"
	fi
}
