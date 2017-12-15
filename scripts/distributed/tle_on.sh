#!/bin/bash
#
# Copyright 2017 IBM Corporation
#
# Enable transactional lock elision within an AT
# enabled binary.
#
# WARNING: unless otherwise stated, the actions
# done here are unique to IBM's advance toolchain,
# and can change at any time for any reason. The
# only guarantee made is the usage of this
# script.
#
# Eventually, this script can be retired, and
# updated with the official glibc tunables
# framework, but until then, what is done here
# is not guaranteed to work between releases
# and may change at any time for any reason.

NAME=${BASH_SOURCE##*/}

function help
{
	cat << EOF
usage: ${NAME} [-e val] [-h] program [args...]

Glibc TLE enables some locks to "skip" locking
and speculatively execute a critical section
guarded by a condition variable, or basic
mutex (i.e. one initialized via
PTHREAD_MUTEX_INITIALIZER).

The runtime characteristics of TLE are largely
a function of the application and the processor
running it.

TLE resources on POWER8 are shared among hardware
threads on a core, so it is best to enable TLE
only on applications which may benefit from this.

This script will start program with the given
args. TLE will be enabled depending on the options
passed to this wrapper script.

Any processes forked or created as result of
running this script will inherit these settings.

-e yes|no
	Enable TLE if value is yes
	Default is yes (on).

-h
	Show this message.

EOF
}

enable_tle=yes

# Coerce string inputs into numbers using let.
while getopts "he:" opt ; do
case $opt in
	h) help; exit 0 ;;
	e) enable_tle="$OPTARG" &> /dev/null;;
        *) help; exit 1 ;;
esac
done

shift "$((OPTIND - 1))"

if [[ "$enable_tle" == "yes" ]]; then
	export GLIBC_TUNABLES=glibc.elision.enable=1
else
	export GLIBC_TUNABLES=glibc.elision.enable=0
fi
exec "$@"
