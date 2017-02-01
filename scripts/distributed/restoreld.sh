#!/bin/bash
#
# Copyright 2017 IBM Corporation

abort() {
	MSG="$@"
	echo "* $MSG"
	cp _`basename $0` $logdir/_`basename $0`
	exit 1;
}

if test -z "$1"; then
	cat <<EOF

 `basename $0` \$1 \$2

 Parameters
 \$1 : Path to Advance Toolchain to adjust, e.g. /opt/at05/

 This script is tasked with restoring the original /opt/at05/bin/ld.

 e.g.

   sh ${scriptdir}/`basename $0` /opt/at05

EOF
	exit 0;
fi

# This sneaky little trick actually enables this script to log itself.  We'll
# copy it to the log directory later.
if [ "$1" != "-already_logging" ]; then
	sh $0 -already_logging $* 2>&1 | tee _`basename $0`
	exit ${PIPESTATUS[0]}
fi
shift # Strip off -already_logging and commence as usual.

echo "+ executing `basename $0` $*"

if test -z "$1"; then
	abort "The directory path to the Advance Toolchain (\$3) must be set."
else
	if test ! -d "$1"; then
		abort "The directory path to the Advance Toolchain ($3) does not exist."
	fi
	# Get the absolute path
	pushd $1 > /dev/null
	AT_PATH="`pwd`"
	popd > /dev/null
fi

if test -e "${AT_PATH}/bin/ld.orig"; then
	cp -p ${AT_PATH}/bin/ld.orig ${AT_PATH}/bin/ld
	rm ${AT_PATH}/bin/ld.orig
	echo "The Advance Toolchain 'ld' has been restored."
else
	echo "The Advance Toolchain 'ld' is already in place."
fi
