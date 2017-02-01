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
 \$1 : Location of ld.hugetlbfs, e.g. /usr/share/libhugetlbfs/ld.hugetlbfs
 \$2 : Path to Advance Toolchain to adjust, e.g. /opt/at05/

 This script is tasked with renaming /opt/at05/bin/ld to
 /opt/at05/bin/ld.orig and then creating a wrapper script in place of
 /opt/at05/bin/ld which invokes /usr/share/libhugetlbfs/ld.hugetlbfs and
 passed /opt/at05/bin/ld.orig as the original linker.

 e.g.

   sh ${scriptdir}/`basename $0` /usr/share/libhugetlbfs/ld.hugetlbfs /opt/at05

EOF
	exit;
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
	abort "The file path to the ld.hugetlbfs parameter (\$1) must be set."
else
	if test ! -e "$1"; then
		abort "The given location of ld.hugetlbfs ($1) does not exist."
	fi
	# Get the absolute path
	pushd `dirname $1` > /dev/null
	LD_HUGE="`pwd`/`basename $1`"
	popd > /dev/null
fi

if test -z "$2"; then
	abort "The directory path to the Advance Toolchain (\$3) must be set."
else
	if test ! -d "$2"; then
		abort "The directory path to the Advance Toolchain ($3) does not exist."
	fi
	# Get the absolute path
	pushd $2 > /dev/null
	AT_PATH="`pwd`"
	popd > /dev/null
fi

LD_ORIG="$AT_PATH/bin/ld.orig"

if test -x "${LD_ORIG}"; then
	echo "There's already a version of the hugetlbfs ld wrapper at $LD_ORIG."
	exit
fi

echo "mv $AT_PATH/bin/ld $LD_ORIG"
cp -p $AT_PATH/bin/ld $LD_ORIG

# This'll overwrite with permissions intact.
cat > $AT_PATH/bin/ld <<EOF
#!/bin/bash

USE_LD_HUGE=""

# Loop through the linker flags looking for --hugetlbfs-link which will
# indicate that we should invoke the libhugetlbfs linker rather than the
# /opt/at05/bin/ld.orig linker.

i=0
while [ -n "\$1" ]; do
    arg="\$1"
    case "\$arg" in
	--hugetlbfs-align)
	    USE_LD_HUGE="yes"
	    args=("\${args[@]}" "\$@")
	    break
	    ;;
	--hugetlbfs-link=*)
	    USE_LD_HUGE="yes"
	    args=("\${args[@]}" "\$@")
	    break
	    ;;
	--)
	    args=("\${args[@]}" "\$@")
	    break
	    ;;
	*)
	    args[\$i]="\$arg"
	    i=\$[i+1]
	    ;;
    esac
    shift
done

if test ! -z "\$USE_LD_HUGE"; then
	# Invoke the hugetlbfs ld
	#echo "LD=\"${LD_ORIG}\" ${LD_HUGE} \"\${args[@]}\""
	LD="${LD_ORIG}" ${LD_HUGE} "\${args[@]}"
else
	# Invoke the original Advance Toolchain ld.
	#echo "${LD_ORIG} \"\${args[@]}\""
	${LD_ORIG} "\${args[@]}"
fi
EOF

# If execute permissions accidentally got removed restore them to the default.
if test ! -x "${AT_PATH}/bin/ld"; then
	chmod +x $AT_PATH/bin/ld
fi

cat $AT_PATH/bin/ld
