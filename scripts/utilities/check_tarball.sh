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

at_major_version=$1
src_file=$2

# Check if the source code contains blocked programs and if the source tarball
# is valid.
echo "Checking the source code tarball..."
# Only packages that require a public source code are provided.
src_list="binutils gcc gdb glibc gmp tbb libdfp libhugetlbfs kernel mpc \
	  mpfr userspace-rcu valgrind libvecpf"
# Block all the others.
blocked_list="amino boost expat gotools libauxv libsphde openssl paflib \
	      python tcmalloc zlib"

# Start distributing libnxz on AT 14.0
if [[ ${at_major_version%%.*} -ge 14 ]]; then
	src_list=${src_list}" libnxz"
fi

file_list=$( tar -tzf ${src_file} | awk -F'[/]' '{print $1}' | uniq )
if [[ $? != 0 || ${file_list} == "" ]]; then
	echo "Source code extraction failed."
	echo "Is the tarball corrupted?"
	exit 1
fi

src_error=0
for file in ${file_list}; do
	# If the package is in the blocked list, then that is
	# an error.
	if [[ "${blocked_list/$file}" != "${blocked_list}" ]]; then
		echo "Package: ${file} should not be included."
		src_error=$((src_error+1))
	else
		# If the package is in the src rpm but not in the
		# expected list then the test needs updating.
		if [[ "${src_list/$file}" == "${src_list}" ]]; then
			echo "Package: ${file} not found in expected list."
			src_error=$((src_error+1))
		fi
	fi
done

for expected in ${src_list}; do
	if [[ "${file_list/$expected}" == "${file_list}" ]]; then
		echo "Missing from src tarball: ${expected}"
		src_error=$((src_error+1))
	fi
done

if [[ ${src_error} == 0 ]]; then
	echo "Source check passed!"
else
	echo "Source check failed!"
	exit ${src_error}
fi
