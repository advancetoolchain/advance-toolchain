#!/bin/bash
#
###############################################################################
# Copyright (c) 2015, 2017 IBM Corporation.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# Contributors:
#   IBM Corporation, Raphael Zinsly - initial implementation and documentation.
#   IBM Corporation, Rafael Sene - filter download by architecture
###############################################################################
#
# The Advance Toolchain (AT) downloader is an automated script which downloads
# the latest AT version for any of the supported Linux distribution. It  gets
# the necessary information regarding the available versions and distributions
# from its official FTP server and downloads the latest AT from a choosen
# version.
#
echo "Advance Toolchain downloader"
at_url="ftp://public.dhe.ibm.com/software/server/POWER/Linux/toolchain/at/"
# Initialize the variables.
pwd=$(pwd)
tmp_file="${pwd}/temp.out"
tmpdir="tmp.$((RANDOM))"
checksums_file="${pwd}/checksums_list.out"
debian="no"

usage()
{
cat << EOF
The Advance Toolchain (AT) downloader is a tool to download the latest
AT for a supported distribution.
To run this script just run it without arguments.
e.g: ./at_downloader.sh
The tool will guide you to select one of the supported distributions and the
version of the Advance Toolchain.

The Advance Toolchain is a self contained toolchain which provides preview
toolchain functionality in GCC, binutils and GLIBC, as well as the debug and
profile tools GDB, and Valgrind.
It also provides a group of optimized threading libraries as well.

Options:
	-h, --help 	       display this help and exit.
	-i, --iso isoname.iso  create ISO image and save it to isoname.iso
EOF
}

# Check if the system has mkisofs, which is required to build the ISO.
have_mkisofs()
{
	mkisofs --version > /dev/null 2>&1 || \
	{
		echo -n >&2 "Could not find mkisofs.  Is it installed?  "
		echo >&2 "Aborting..."
		exit 1
	}
	return
}

# Check whether the filename given for the iso is valid
check_isofile()
{
	if [[ "$1" =~ [^a-zA-Z0-9.] ]]; then
		echo "Invalid filename ($1). " \
		     "Use only alphanumeric characters and dots.  Aborting."
		exit 1
	fi
}

# Parse input options
MAKEISO=false
while [[ $# > 0 ]]
do
	key="$1"
	case $key in
		-h|--help)
			usage
			exit 0
			;;
		-i|--iso)
			have_mkisofs
			MAKEISO=true
			ISOFILE=$2
			check_isofile $ISOFILE
			shift
			;;
		*)
			usage
			exit 1
			;;
	esac
	shift
done

# Verify if lsb_release and wget are available.
for program in lsb_release wget; do
	if ! type "${program}" > /dev/null; then
		echo "${program} is not found in the system."
		echo "Please install ${program} and try again."
		exit 1
	fi
done

# Delete the intermediate files and exit with signal $1.
clean_exit ()
{
	# Move files from the temporary directory to the requested destination
	rm -f ${output}/${tmpdir}/*SUMS
	shopt -s dotglob
	mv ${output}/${tmpdir}/* ${output}/
	rmdir ${output}/${tmpdir}

	# Delete intermediate files
	rm ${tmp_file} ${checksums_file} .listing 2> /dev/null

	exit $1
}

# Get the list of directories in a given array and print it.
# Parameters:
#   $1 - Name of the array with the options.
print_directories ()
{
	i=1
	array_name=$1[@]
	array=( "${!array_name}" )
	for element in ${array[@]}; do
		echo "${i}. ${element}"
		i=$((i+1))
	done
}

# Handle the option chosen by the user.
# Parameters:
#   $1 - Name of the array with the options.
#   $2 - Option chosen.
#   $3 - Default option.
handle_option ()
{
	array_name=$1[@]
	array=( "${!array_name}" )
	option=${2}
	if [[ "$( echo ${option} | grep "^-*[ [:digit:] ]*$" )" ]]; then
		# Guarantee that the option is in range.
		if [[ ${option} -le ${#array[@]} && ${option} -gt 0 ]]; then
			option=${array[$((option-1))]}
		else
			exit
		fi
	else
		option=${option:-${3}}
	fi
	echo "${option}"
}

# Get the list of files from an URL.
# Parameters:
#   $1 - URL.
#   $2 - Term to be filtered by grep.
list_files ()
{
	wget -q --no-remove-listing -O - ${1}/ > /dev/null
	cat .listing | awk '{print $9}' | grep ${2} | tr '\r' ' '
}

# Get the system's distribution name, vendor and ID.
distro_rawname=$( lsb_release -i | cut -d":" -f 2 | sed "s/^[ \t]*//" \
		  | tr [:upper:] [:lower:] )
distro_id=$( lsb_release -r | cut -d":" -f 2 | sed "s/^[ \t]*//" \
	     | cut -d"." -f 1 )
case ${distro_rawname} in
	redhat*)
		vendor_name="redhat"
		distro_name="RHEL${distro_id}"
		;;
	fedora)
		vendor_name="redhat"
		distro_name="Fedora${distro_id}"
		;;
	*suse*)
		vendor_name="suse"
		distro_name="SLES_${distro_id}"
		;;
	ubuntu*)
		vendor_name="ubuntu"
		distro_name=$( lsb_release -c | cut -d":" -f 2 )
		;;
	debian)
		vendor_name="debian"
		distro_name=$( lsb_release -c | cut -d":" -f 2 )
		;;
	*)
		vendor_name=""
		distro_name=""
		;;
esac;

# Get the vendor from user.
vendors=($( list_files "${at_url}" "-ve ^at -e ^\." ))
echo "Vendors:"
print_directories vendors
echo -n "Please, choose the vendor"
if [[ -n ${vendor_name} ]]; then
	echo -n " (${vendor_name})?"
fi
read -e -p ": " vendor
vendor=$( handle_option vendors ${vendor} ${vendor_name} )
if [[ -z ${vendor} ]]; then
	echo "Error: Vendor not chosen!"
	clean_exit 1
fi
echo "Collecting information..."

# Print indicates which word to print in the awk scripts.
if [[ ${vendor} == "ubuntu" || ${vendor} == "debian" ]]; then
	debian="yes"
	vendor="${vendor}/dists"
fi

# Get the distro from user.
all_distros=$( list_files "${at_url}/${vendor}/" "[a-zA-Z]" | sort -rV )
if [[ ${#all_distros[@]} == 0 ]]; then
	echo "Error: Vendor not supported!"
	clean_exit 1
fi

# Find all supported distros and its AT's versions.
j=0
for dist in ${all_distros[@]}; do
	# Get the AT versions listed in that distribution.
	all_versions=$( list_files "${at_url}/${vendor}/${dist}/" "^at" \
			| sort -rV )
	i=0
	# Get the AT's versions supported for this distro.
	for ver in ${all_versions[@]}; do
		if [[ ${debian} == yes ]]; then
			directory="${ver}/binary-ppc64el"
		else
			directory="${ver}"
		fi
		# Verify if the AT directory has devel packages.
		wget -q -O - ${at_url}/${vendor}/${dist}/${directory}/ \
		     | grep devel > ${tmp_file}
		if [[ -s ${tmp_file} ]]; then
			at_versions[${i}]=${ver}
			i=$((i+1))
		fi
	done
	if [[ ${#at_versions[@]} != 0 ]]; then
		sup_distros[${j}]=${dist}
		if [[ ${debian} == "yes" ]]; then
			# Get a number for the first char on debian distros.
			number=$( echo ${dist} | cut -c1 | od -A n -i )
		else
			# Get the version number.
			number=$( echo ${dist} | sed -E 's/[0-9]+/_&/' \
				  | awk -F'[_]+' '{print $2}' )
		fi
		distro_versions[${number}]=${at_versions[@]}
		j=$((j+1))
	fi
	unset at_versions
done

# If the system's vendor was choosen, use the system's distro as default.
if [[ ${vendor} != ${vendor_name} ]]; then
	distro_name=${sup_distros[0]}
fi
echo "Distributions:"
print_directories sup_distros
read -e -p "Choose the distribution (${distro_name})?: " distro
distro=$( handle_option sup_distros ${distro} ${distro_name} )
if [[ ${debian} == "yes" ]]; then
	number=$( echo ${distro} | cut -c1 | od -A n -i )
else
	number=$( echo ${distro} | sed -E 's/[0-9]+/_&/' \
		  | awk -F'[_]+' '{print $2}' )
fi
at_versions=( ${distro_versions[${number}]} )
if [[ ${#at_versions[@]} == 0 ]]; then
	echo "Error: Distribution ${distro} not supported!"
	clean_exit 1
fi

# Get the latest AT's version.
at_latest=${at_versions[0]}

# Get the AT's version from user.
echo "AT versions:"
print_directories at_versions
read -e -p "Enter the version of AT (${at_latest})?: " at_major
at_major=$( handle_option at_versions ${at_major} ${at_latest} )
# Strip "at" from the version string.
at_major=$( echo ${at_major} | tr -d "at" )

# Get the output path from user.
read -e -p "Enter the output directory (${pwd})?: " output
output=${output:-${pwd}}

# Set the url for at_major directory in the FTP.
url="${at_url}/${vendor}/${distro}/at${at_major}/"

# Get the list of files in the distro/at_major directory.
# Filter the AT's minor versions from release notes file names.
wget -q -O - ${url} | awk -F'[.-]' '{print $9}' > ${tmp_file}
# Get the latest minor version from AT.
at_minor=$( cat ${tmp_file} | grep -e ^[0-9] | tail -1 )
# Verify if there is native packages for that distro.
if [[ -z ${at_minor} ]]; then
	# Check if ${tmp_file} has data.
	if [[ ! $( cat ${tmp_file} ) ]]; then
		echo "Error: This AT version doesn't have support to this \
distro."
		clean_exit 1
	else
		echo "AT ${at_major} has only compat and/or cross packages for \
${distro}."
		clean_exit 1
	fi
fi

# Get the user architecture in order to download only a specific
# set of packages
echo "Architecture:"
user_arch=$(uname -m)
if [[ ${debian} == yes ]]; then
	at_archs=($( wget -q -O - ${url} | grep -oE '>binary-[/A-Za-z0-9-]+<' | \
	awk -F'[-/]' '{print $2}' | sort ))
else
	at_archs=($( wget -S --spider ${url} 2>&1 | grep -o -P \
    	"(?<=${at_major}-${at_minor}).*(?=rpm)" | tr -d . | sort | uniq ))
fi
print_directories at_archs
read -e -p "Choose the architecture (${user_arch})?: " at_arch
at_arch=$( handle_option at_archs ${at_arch} ${user_arch} )

# Debian systems have a different directory structure.
if [[ ${debian} == "yes" ]]; then
	if [ ${at_arch} == 'ppc64le' ];then
		at_arch='ppc64'$(echo "${at_arch: -2}" | rev)
	fi
	download_url="${url}/binary-$at_arch/*${at_major}-${at_minor}*"
	# Set to download DEB packages.
	extensions="deb"
else
	download_url="${url}/*${at_major}-${at_minor}*.${at_arch}.*"
	# Set to download RPM packages.
	extensions="rpm"
fi

# Enter in the output directory.
mkdir -p ${output}/${tmpdir}
pushd ${output}/${tmpdir}
if [[ $? -ne 0  ]]; then
	echo "Error: Not able to access ${output}!"
	clean_exit 1
fi

# Check if remote file exists then download it
if [[ `wget -S --spider ${download_url}  2>&1 | grep -o -P \
    '(?<=File).*(?=exists)'` ]]; then
	# Download the packages.
	echo "Downloading AT ${at_major}-${at_minor} on $(pwd) ..."
	wget -A ${extensions} --progress=dot:mega ${download_url} 2>&1 \
	| grep -E ' =>|[KM] \.| saved '
	if [[ $? -ne 0 ]]; then
		echo "Error: The packages were not downloaded correctly."
		clean_exit 1
	fi
else
	echo 'Could not download '${download_url}
	clean_exit 1
fi

# Verify the md5sum of the files downloaded.
echo "Checking the integrity of the files..."
# Get the list of packages and the checksums from the server.
if [[ ${debian} == "yes" ]]; then
	wget -q -O - "${url}/binary-$at_arch/" \
	     | grep deb | awk -F'[/"]' '{print $16}' > ${tmp_file}
	wget -q -O ${checksums_file} "${url}/binary-$at_arch/Packages"
else
	wget -q -O - ${url} | grep rpm | awk -F'[/"]' '{print $13}' \
	     > ${tmp_file}
	wget -q -O ${checksums_file} ${url}/MD5SUMS
fi
files=$( cat ${tmp_file} | grep ${at_major}-${at_minor} )
for file in ${files}; do
	if [[ ${file} == *.${at_arch}.* ]]; then
		checksum=$( md5sum ${file} | awk '{print $1}' )
		cat ${checksums_file} | grep ${checksum} > /dev/null 2>&1
		if [[ $? -ne 0 ]]; then
			echo "File ${file} corrupted!"
			clean_exit 1
		fi
	fi
done
echo "All files are good."
popd

echo "Advance Toolchain successfully downloaded!"

# Create ISO image if requested
if [ $MAKEISO == true ]; then
	# Create the checksums
	pushd ${output}/${tmpdir}
	md5sum *.{rpm,deb} > MD5SUMS 2> /dev/null
	sha1sum *.{rpm,deb} > SHA1SUMS 2> /dev/null
	sha256sum *.{rpm,deb} > SHA256SUMS 2> /dev/null
	popd
	# Create the ISO image
	pushd ${output}
	mkisofs -iso-level 4 -o $ISOFILE ${tmpdir}/
	retcode=$?
	if [ ${retcode} == 0 ]; then
		echo "ISO file ($ISOFILE) successfully created."
	else
		echo "ISO file ($ISOFILE) could not be created.  Aborting."
		clean_exit 1
	fi
	popd
fi

clean_exit 0
