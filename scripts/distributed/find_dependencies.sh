#/bin/bash
# Copyright (C) 2016 IBM Corporation

# Generate requirements for executables built with Advance Toolchain.
# This script should replace the one in the macro %__find_requires in the RPM
# spec file, please check http://ibm.co/AdvanceToolchain for more information.

tmp_file=$(mktemp)

# Ignore these dependencies.
ignored="linux-vdso|libselinux|libaudit|linux-gate"

help ()
{
	cat <<EOF
Usage: ${0} [OPTION] <FILES>

Print the list of requirements of <FILES>.  This list is useful to fill the
field "Requires" in a RPM spec file.

Options:
  -h|--help		display this help and exit
EOF
}

# This script requires at least one argument.
if [[ ${#} -le 0 ]]; then
	help
	# Invalid argument.
	exit 22
fi

case "${1}" in
	-h|--help)
		help
		exit 0
		;;
esac

if [[ $(uname -m) != ppc* ]]; then
	is_cross=yes
fi;

readelf_path=$(which readelf)
for file in "${@}"; do
	# Ignore files we can't read or execute.
	if [[ ! -x ${file} ]] || [[ ! -r ${file} ]]; then
		continue
	fi

	# Ignore the loader.  Are you using the Advance Toolchain to build
	# glibc?
	if [[ "${file}" == ld-*.so ]]; then
		continue
	fi

	file_info=$(file ${file})
	# If it isn't dynamically linked, we aren't interested.
	echo "${file_info}" | grep "dynamically linked" &> /dev/null
	if [[ ${?} -ne 0 ]]; then
		continue
	fi

	if [[ ${is_cross} == "yes" ]]; then
		# In a cross environment, we don't provide requirements on
		# PowerPC executables for RPM packages.
		${readelf_path} -h ${file} | grep "PowerPC" &> /dev/null
		if [[ ${?} -eq 0 ]]; then
			continue
		fi
	fi

	wordsize=$(echo "${file_info}" \
			| sed -e 's/^.*ELF //g' -e 's/-bit.*$//')
	if [[ ${wordsize} -eq 32 ]]; then
		suffix=
	elif [[ ${wordsize} -eq 64 ]]; then
		# This is a RPM requirement.
		suffix="()(64bit)"
	else
		echo "Can't recognize ${file} word size" 1>&2
		exit 1
	fi;

	# Get the interpreter.  The interpreter will tell us if this file was
	# built using AT or not.
	interpreter=$(${readelf_path} -e ${file} \
			| grep 'interpreter' \
			| sed 's/\[.*\: \(.*\)\]/\1/')
	at_path=${interpreter%%/lib*}
	if [[ ${is_cross} != "yes" && ${interpreter} == /opt/at* ]]; then
		ldd_path=${at_path}/bin/ldd
	else
		ldd_path=$(which ldd)
	fi;
	# Treat non-AT files first.
	${ldd_path} -v ${file} | grep -v "${at_path:=^$}" | sed -n \
		"s/^[ \t]*\([^ ]\+\) \?(\?\([^ ]*\))\? =>.*$/\1${suffix}/p" \
		>> ${tmp_file}
	if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
		echo "Failed to ldd file ${file}" 1>&2
		exit 1
	fi

	# Treat AT-provided files.
	if [[ -n "${at_path}" ]]; then
		for requirement in $(${ldd_path} ${file} \
						| grep ${at_path} \
						| awk '/=>/ {print $3}'); do
			# Output the name of the package, instead of the name
			# of the library.
			rpm -q --qf "%{NAME} >= %{VERSION}-%{RELEASE}\n" \
			    -f ${requirement} >> ${tmp_file}
		done
	fi
done

# Print the result.
sort -u ${tmp_file} | grep -vE "${ignored}"

# Remove the temporary file.
rm -f ${tmp_file} &> /dev/null
