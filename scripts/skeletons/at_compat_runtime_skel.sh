#!/bin/sh
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
# at-compat Compatibility mode to run AT __AT_OVER__ apps on AT __AT_VER__
#
# chkconfig:   2345 70 30
# description: The Advance Toolchain is a self contained toolchain which \
#              provides preview toolchain functionality in GCC, binutils, \
#              GLIBC, GDB, and Valgrind. \
#              This service enables a compatibility mode to run programs
#              compiled with old versions of the Advance Toolchain on top of \
#              the current version.

### BEGIN INIT INFO
# Provides: at-compat
# Required-Start: $local_fs $syslog
# Required-Stop: $local_fs $syslog
# Should-Start: $syslog
# Should-Stop: $syslog
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: Compatibility mode to run AT __AT_OVER__ apps on AT __AT_VER__
# Description:      The Advance Toolchain is a self contained toolchain
#                   which provides preview toolchain functionality in GCC,
#                   binutils, GLIBC, GDB, and Valgrind.
#                   This service enables a compatibility mode to run programs
#                   compiled with old versions of the Advance Toolchain
#                   on top of the current version.

### END INIT INFO

dest=__AT_DEST__
odest=__AT_ODEST__

if [[ "x${dest}" == "x" ]]; then
	echo "Error: Advance Toolchain directory has not been set." >&2
	exit 1
fi

if [[ "x${odest}" == "x" ]]; then
	echo "Error: Advance Toolchain previous directory has not been set" >&2
	exit 1
fi

start() {
	[[ ! -d "${dest}/lib" ]]    && echo "${dest}/lib doesn't exist." \
		&& exit 1
	[[ ! -d "${dest}/lib64" ]]  && echo "${dest}/lib64 doesn't exist." \
		&& exit 1
	[[ ! -d "${odest}/lib" ]]   && echo "${odest}/lib doesn't exist." \
		&& exit 1
	[[ ! -d "${odest}/lib64" ]] && echo "${odest}/lib64 doesn't exist." \
		&& exit 1

	mount --bind "${dest}/lib" "${odest}/lib" \
		&& mount --bind "${dest}/lib64" "${odest}/lib64"
	return ${?}
}

stop() {
	umount "${odest}/lib" \
		&& umount "${odest}/lib64"
	return ${?}
}

status() {
	mount -l | grep "${odest}/lib" &> /dev/null
	return ${?}
}

restart() {
	stop
	start
}

case "${1}" in
	start)
		status && exit 0
		start
		;;
	stop)
		status && stop
		;;
	status)
		status
		;;
	restart)
		restart
		;;
	*)
		echo "Usage: $0 {start|stop|status|restart}"
		exit 2
esac

exit ${?}
