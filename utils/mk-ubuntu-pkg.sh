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

# Convert AT cross-compiler RPMs to DEB.

usage ()
{
cat <<EOF
Usage: sudo ${0} <rpm package>
	$1 - RPM package being converted to deb
EOF
}

if [[ ! -f "${1}" ]]; then
	echo "Can't find ${1}"
	usage
	exit 1
fi

# Some commands executed here only work as root
if [[ "$(whoami)" != "root" ]]; then
	echo "You must execute this script as root."
	exit 1
fi

arch=$(rpm -qi -p ${1} | awk '/Architecture:/ { print $2 }')
dirname=$(basename "${1}" | sed "s/\(.*\)-[0-9].*\.${arch}\.rpm/\1/")

set -ex

{
	alien -c -k -g "${1}"

	pushd ${dirname} > /dev/null

	name=$(sed '/^Description:/!d;s/^Description: //' debian/control)
	version=$(head -n 1 debian/changelog | sed 's/^.* (\([^)]*\)) .*$/\1/')

	# Prepare control file
	cp debian/control debian/control.orig
	grep -v "Converted from" debian/control \
	     | grep -Ev -Ev "^ \.$" \
	     > debian/control.2
	# Make this package able to  install both on i386 and x86_64
	echo "Multi-Arch: foreign" >> debian/control.2
	sed -e "s/\(Maintainer: \).*/\1${name}/" \
	    -e "s/\(Section: \).*/\1devel/" \
	    -e "s/\(Depends: \).*/\1libc6 (>= 2.15), zlib1g (>= 1.2.3), libstdc++6 (>= 4.6.3), libncurses5 (>= 5.9), libtinfo5 (>= 5.9)/" \
	    debian/control.2 > debian/control
	rm debian/control.2

	# Prepare copyright file
	cp debian/copyright debian/copyright.orig
	cat <<EOF > debian/copyright
Format: http://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
License: GPL, LGPL
EOF

	# Remove erroneous content from the changelog file
	# TODO: Add a proper content based on what we add to the release notes.
	cp debian/changelog debian/changelog.orig
	sed -e "s/^  \* .*$/  * Release of ${name} ${version}/" \
	    -e "s/^ -- .*  / -- ${name}  /" \
	    debian/changelog > debian/changelog.2
	mv debian/changelog.2 debian/changelog

	# Avoid the forced removal of /opt/atXX.0. Doing so may cause a bug
	# while updating the package.
	rm -f debian/postrm

	# Build deb package
	debian/rules binary

	popd > /dev/null
} 2>&1 | tee _$(basename ${0}).log

set +ex
