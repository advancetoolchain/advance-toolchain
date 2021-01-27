#!/bin/bash
#
# Copyright 2021 IBM Corporation
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
# This script compares the upstream version number with the version number
# stored in the given config/source file.
#
# Usage:
#  check_versions <config/package/source> [<revision>]
#
# In addition to the config/source file, a revision could be given. If so,
# it's used instead of the value of ATSRC_PACKAGE_REV from the config/source file.
#
# Exit codes:
#     0: OK
#     1: versions mismatch
#     2: something is wrong with the script
#

function usage() {
    echo "usage $0 <config/package/source> [<revision>]"
    exit 2
}

[[ ${#} -lt 1 ]] || [[ ${#} -gt 2 ]] && usage

source $1
[[ $? -ne 0 ]] && exit 2

# If ATSRC_PACKAGE_VER is set to master, the check is skipped.
if [[ "${ATSRC_PACKAGE_VER}" == "master" ]]; then
    echo "In AT: ${ATSRC_PACKAGE_VER}"
    exit 0
fi

revision=${ATSRC_PACKAGE_REV}
[[ -n "$2" ]] && revision=$2

package=$(readlink -f $1 | tr "/" "\n" | tail -n 2 | head -n 1)
case "$package" in
    binutils)
        out=$(wget -qO - "https://sourceware.org/git/?p=binutils-gdb.git;a=blob_plain;f=bfd/version.m4;hb=${revision}" | grep "^m4_define")
        ;;
    expat)
        out=$(wget -qO - "https://raw.githubusercontent.com/libexpat/libexpat/${revision}/expat/lib/expat.h" | grep "XML_M.*_VERSION" | sed "s/^.*VERSION //" | paste -d "." - - -)
        ;;
    gcc)
        out=$(wget -qO - "https://gcc.gnu.org/git/?p=gcc.git;a=blob_plain;f=gcc/BASE-VER;hb=${revision}")
        ;;
    gdb)
        out=$(wget -qO - "https://sourceware.org/git/?p=binutils-gdb.git;a=blob_plain;f=gdb/version.in;hb=${revision}")
        ;;
    glibc)
        out=$(wget -qO - "https://sourceware.org/git/?p=glibc.git;a=blob_plain;f=version.h;hb=${revision}" | grep -w "VERSION")
        ;;
    golang)
        out=$(wget -qO - "https://raw.githubusercontent.com/powertechpreview/go/${revision}/VERSION" | head -n 1)
        ;;
    libdfp)
        out=$(wget -qO - "https://raw.githubusercontent.com/libdfp/libdfp/${revision}/configure" | grep PACKAGE_VERSION=)
        ;;
    libhugetlbfs)
        out=$(wget -qO - "https://raw.githubusercontent.com/libhugetlbfs/libhugetlbfs/${revision}/NEWS" | head -1)
        ;;
    libpfm)
        out=$(wget -qO - "https://sourceforge.net/p/perfmon2/libpfm4/ci/${revision}/tree/debian/changelog?format=raw" | grep -m1 libpfm4 | sed "s/^libpfm4 (\([0-9]*\)\.\([0-9]*\)).*$/4.\1.\2/")
        ;;
    liburcu)
        out=$(wget -qO - "http://git.liburcu.org/?p=userspace-rcu.git;a=blob_plain;f=configure.ac;hb=${revision}" | grep "AC_INIT" | cut -c1-80)
        ;;
    openssl)
        out=$(wget -qO - "https://raw.githubusercontent.com/openssl/openssl/${revision}/CHANGES" | grep -m1 "^ Changes between .* and .*xx XXX xxxx")
        ;;
    python)
        out=$(wget -qO - "https://raw.githubusercontent.com/python/cpython/${revision}/README.rst" | head -n1 | grep "This is Python version ")
        ;;
    tbb)
        out=$(wget -qO - "https://raw.githubusercontent.com/01org/tbb/${revision}/include/tbb/tbb_stddef.h" | grep TBB_VERSION_M[AI] | sort | sed "s/[^0-9]*//g" | tr "\n" "." | cut -d. -f1-2)
        ;;
    tcmalloc)
        out=$(wget -qO - "https://raw.githubusercontent.com/gperftools/gperftools/${revision}/configure.ac" | grep "AC_INIT")
        ;;
    valgrind)
        out=$(wget -qO - "https://sourceware.org/git/?p=valgrind.git;a=blob_plain;f=configure.ac;hb=${revision}" | grep -m 1 "^AC_INIT")
        ;;
    *)
        echo "unknown package: $package"
        exit 2
        ;;
esac

echo "Upstream: $out"
echo "In AT: ${ATSRC_PACKAGE_VER}"

echo "$out" | grep -q "${ATSRC_PACKAGE_VER}"
