#!/bin/bash
#
# Copyright 2017 IBM Corporation

# This script is used to generate XL cfg files so that a program built with
# the XL compiler will use the runtime libraries from the Advance Toolchain,
# instead of the native installed libraries.

# The script can be invoked manually by:
# >cd /usr
# >/opt/at13.0/scripts/at-create-ibmcmp-cfg.sh
#  ---- OR to explicitly indicate the compiler path ----
# >xl_base=/opt/ibm /opt/at13.0/scripts/at-create-ibmcmp-cfg.sh
#
# For vac 11.1/xlf 13.1 and earlier releases, the compilers and
# runtime libraries are found under /opt/ibmcmp.  Starting in xlC 13.1/xlf 15.1,
# the compiler invocations are under /opt/ibm, and the runtime libraries are
# still under /opt/ibmcmp.
#
# If /opt/ibm/xlf or /opt/ibm/xlC exist, then the default value for xl_base is
# /opt/ibm.  In all other cases the default value for xl_base is /opt/ibmcmp.
#
# If the system has multiple versions of the XL compilers installed, then
# invoking this script with the explicit value for xl_base will cause the
# complete set of cfg files to be generated.

#
# This function checks the presence of a string pattern inside a string stream.
# We use this function to find out if some parameter is supported by a
# particular script.
#
# ${1} - The haystack (file / string stream) to look for a pattern
# ${2} - The needle pattern to look for... ;-)
# ${3} - Kind of search to perform "in_file" or "in_string"
#
# Returns:
# 0 - needle was found in the haystack
# 1 - needle wasn't found in the haystack
#
function check_parameter ()
{
	# Set the kind of search to perform ("in_file" / "in_string")
	local kindOfSearch=${3}
	# If search is "in_file", transform haystack into a stream string with
	# the content of the file that it points to. Otherwise let it as is.
	if [[ "${kindOfSearch}" == "in_file" ]]; then
		local haystack=$(cat ${1})
	else
		local haystack=${1}
	fi
	# Prepare the Extended RegExp (ERE) with the two possible variations
	# of the pattern to look for
	local needle="(${2}|'${2}')"


	# Perform the search of the pattern
	if [[ -n "$(grep -Eo "${needle}" <<< ${haystack})" ]]; then
		return 0
	else
		return 1
	fi
}


#
# Check if XL license has been accepted.
#
# ${1} - Path the to license file.
xl_license_accepted ()
{
	if grep -i 'status=9' "${1}" > /dev/null 2>&1; then
		return 0
	else
		return 1
	fi
}


#
# Create a config file for the XL compiler. If it already exists, recreate it.
#
# $1 - Version of the compiler.
# $2 - Name of the compiler.
# $3 - Prefix of the compiler (usually /opt/ibm or /opt/ibmcmp).
create_config ()
{
	local version="${1}"
	local compiler="${2}"
	# Prefix of the XL compiler.
	local xlb="${3}"

	local ver_str=$(echo ${version} | tr [.] [_])
	local config="${at_scripts}/${compiler}-${ver_str}-${at_str}.dfp.cfg"

	if ls ${config} &> /dev/null; then
		echo "File ${config} already exists. Recreating it!"
		rm -rf ${config}
	fi

	if [ "${compiler}" == "xlC" ]; then
		local cmp="xlc"
	else
		local cmp="${compiler}"
	fi

	# Define the standard (old) configure script
	local config_script="${xlb}/${compiler}/${version}/bin/${cmp}_configure"
	# Define the updated (new) new_install configure script
	local new_install="${xlb}/${compiler}/${version}/bin/new_install"
	# Define the license file to check for a valid license
	local status_license="${xlb}/${compiler}/${version}/lap/license/status.dat"
	# Define the temp logfile to use
	local logfile=$(mktemp /tmp/at-${compiler}.XXXXXX)
	# Define the XL config file to produce
	local xl_base_file="${xlb}/${compiler}/${version}/etc/${cmp}.base.cfg"

	# First new check the availability of '-at' option on xl*_configure script
	if [[ -f "${config_script}" ]] && check_parameter "$(${config_script} -h)" "-at" "in_string"; then
		# Confirm that the license was accepted previously
		if xl_license_accepted "${status_license}"; then
			# Set the required default parameters
			local config_parameters="-gcc ${at} -o ${config}"
			# Check optional parameter -gcc64
			check_parameter "$(${config_script} -h)" "-gcc64" "in_string" && \
				config_parameters="${config_parameters} -gcc64 ${at}"
			# Check optional parameter -ibmcmp
			check_parameter "$(${config_script} -h)" "-ibmcmp" "in_string" && \
				config_parameters="${config_parameters} -ibmcmp ${xlb}"
			# Check optional parameter -ibmrt
			check_parameter "$(${config_script} -h)" "-ibmrt" "in_string" && \
				config_parameters="${config_parameters} -ibmrt ${xl_basert}"
			# Check optional parameter -dfp
			check_parameter "$(${config_script} -h)" "-dfp" "in_string" && \
				config_parameters="${config_parameters} -dfp ${xl_base_file}"
			# Run the script with the correct parameters and log
			echo "    ${config_script} ${config_parameters}"
			{
				${config_script} ${config_parameters}
			} &> ${logfile}
			if [ $? != 0 ]; then
				echo "Error creating the config file. Aborting XLC/XLF config" \
				     "file generation."
				echo "A log is available at ${logfile}"
				echo "If you need config files for XLC/XLF, please refer to" \
				     "your XLC/XLF config documentation on how to create" \
				     "them manually."
				exit 1
			fi
			# Run the script with the -at parameter alone.
			# This run of the configuration script only changes the
			# internal config files of the referred XL compiler, so
			# it doesn't touch those configs inside Advance
			# Toolchain folder tree, generated above.
			echo "    ${config_script} -at ${at}"
			{
				${config_script} -at ${at}
			}  &> ${logfile}
		# Without a valid license, instruct user and abort configuration
		else
			echo "Your XLC/XLF license wasn't accepted yet." \
			     "Aborting XLC/XLF config file generation."
			echo "A log is available at ${logfile}"
			echo "Please accept the XLC/XLF license prior to" \
			     "this, and only then run '${config_script} -at ${at}'" \
			     "manually."
			exit 1
		fi
	# Check and configure which one to use (old or new)
	elif [[ -f "${new_install}" ]] \
		 && check_parameter "${new_install}" "-at" "in_file"; then
		if ! xl_license_accepted "${status_license}"; then
			echo "Your XLC/XLF license wasn't accepted yet." \
			     "Aborting XLC/XLF config file generation."
			echo "A log is available at ${logfile}"
			echo "Run '${new_install} -at ${at}' manually."
			exit 1
		fi

		local config_parameters="-at"
		# Check support for non-standard AT directories.
		check_parameter "${new_install}" "AT_PREFIX" "in_file" \
			&& config_parameters="${config_parameters} \"${at}\""

		# Run the script with the correct parameters and log
		echo "    ${new_install} ${config_parameters}"
		{
			${new_install} ${config_parameters}
		} &> ${logfile}

	# Usual process became the secure fall back
	else
		# Check required script's existence
		if [ ! -f "${config_script}" ]; then
			echo "Cannot find $config_script"
			return 1
		fi
		# Run the script with the correct parameters and log
		echo "    ${config_script} -gcc ${at} -gcc64 ${at} " \
		     "-ibmcmp ${xlb} -o ${config}" \
		     "-ibmrt ${xl_basert}" \
		     "-dfp ${xl_base_file}"
		{
			${config_script} -gcc "${at}" -gcc64 "${at}" \
					 -ibmcmp ${xlb} -o "${config}" \
					 -ibmrt ${xl_basert} \
					 -dfp "${xl_base_file}"
		} &> ${logfile}
	fi
	if [ $? != 0 ]; then
		echo "Error creating the config file. Aborting XLC/XLF config" \
		     "file generation."
		echo "A log is available at ${logfile}"
		echo "If you need config files for XLC/XLF, please refer to" \
		     "your XLC/XLF config documentation on how to create" \
		     "them manually."
		exit 1
	fi
	return 0
}


# Identify AT parameters
at_scripts=${0%/*}
at=${at_scripts%/*}
at_str=`echo ${at##*/} | tr [a-z.] [A-Z_]`

# Test permissions
touch ${at_scripts}/testfile > /dev/null 2>&1
if [ $? != 0 ]; then
	echo "You do not have permission to write at ${at_scripts}"
	echo "Please re-run this script as root."
	exit 1
fi
rm ${at_scripts}/testfile

# This is the default installation path for XL
if [[ -z ${xl_base} ]]; then
	if [[ -e '/opt/ibm/xlf' || -e '/opt/ibm/xlC' ]]; then
		# New path, since xlC 13.1 and xlf 15.1.
		xl_base='/opt/ibm'
	else
		xl_base='/opt/ibmcmp'
	fi
fi

# Note that the path for the compiler invocations is different in
# xlC 13.1 and xlf 15.1, even though the runtime libraries remain
# in the same location.
# It turned out that on xlC 13.1.1 and xlf 15.1.1, they updated the
# runtime library path to the same new place, removing /opt/ibmcmp
# completely.
if [[ -z ${xl_basert} ]]; then
	if [[ -d '/opt/ibmcmp' ]]; then
		xl_basert='/opt/ibmcmp'
	else
		xl_basert=${xl_base}
	fi
fi

# Test XL installation
echo "Testing for optional IBM XL compilers installation..."
echo "This will check for XLC/XLF availability and create config files for" \
     "them in $at_scripts"
ls ${xl_base} > /dev/null 2>&1
if [ $? != 0 ]; then
	echo "IBM XL compilers not found in its default location at $xl_base"
	echo "If it is installed somewhere else, please re-run:"
	echo "xl_base=<your-install-dir> $0"
	exit 0
else
	echo "IBM XL compilers found in $xl_base"
fi

# Create the config files
for xlb in ${xl_base}; do
	for compiler in vac xlf xlC; do
		if [ -d "${xlb}/${compiler}" ]; then
			for version in `\ls ${xlb}/${compiler}`; do
				create_config ${version} ${compiler} ${xlb}
			done
		fi
	done
done

echo "All config files created in $at_scripts and are ready for use."
echo "If you need to use XLC/XLF with the Advance Toolchain, invoke the XL" \
     "compiler suite using -F$at_scripts/<generated_config_file>."
exit 0
