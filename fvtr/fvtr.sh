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

# This script is the main driver script for the Function Verification Test
# An optional argument is a list of tests to be run.  Each test will be in
# its own subdirectory and the name of the primary test script is the
# subdirectory’s name with a .exp extension.  If the list of tests is not
# supplied, this script will run all tests.  It does this
# by creating a list of subdirectories and loops thru the list calling each
# ‘primary’ test script in that directory.

# The test scripts are passed three arguments, the name of the script being
# run, where to direct the output, and the AT_PLATFORM on which the test is
# being run.

LOUD=OFF
FORCE=OFF
SCRIPTS2RUN=ALL
TESTS2RUN=""
CONFIGFILE=""

function usage () {
	echo "Usage: fvtr [-fl] <configfile> [test1 test2 ...]"
	echo "       fvtr report"
	echo ""
	echo "       -f Force the test(s) to be run"
	echo "       -l Output is sent to the console"

	echo "       '<configfile>' path to the config file used to build AT"
	echo "       tests -  a list of tests to run (optional).  It is going"
	echo "                to run all tests by default."
	echo "       Example: fvtr -f ~/advance-toolchain/config.at5.0.sles10 "
	echo ""
	echo "       report - prints content of log files that failed. This"
	echo "                command does not run tests again. Instead, it"
	echo "                only takes the logs of the last test that was"
	echo "                ran with fvtr.sh in order to print relevant"
	echo "                information. It's also important to note that"
	echo "                this implies that a test must be necessarily"
	echo "                ran without the -l option in order to enable"
	echo "                later usage of the report command."
	exit 0
}

runall()
{
	TEMPS2RUN=$(find -type d | sort)
	rdot='.'
	rslash='/'
	# rebuld this list with out the ./
	# strip off the . and ./ and concat the results in to a new list
	for i in $TEMPS2RUN
	do
		temp=${i/#$rdot/''}
		temp=${temp/#$rslash/''}
		TESTS2RUN=$TESTS2RUN" "$temp
	done
}

if [[ ${1} = "report" ]];
then
	if [ ! -e "report.log" ];
	then
		echo "Error: no logs for previous tests were found."
		exit 1
	fi

	printcount=0

	logname=$(awk 'NR==1' report.log)
	while read line
	do
		testname=$(awk '{print $1}' <<< "$line")

		# If no tests fail, a blank line is left in report.log,
		# which we should ignore.
		if [[ $testname = "" ]];
		then
			continue
		else
			printcount=$(($printcount+1))
		fi

		# Here we generate enough '*' so that "Log file content"
		# lines have the same length, for readability purposes
		bar=$(printf "%0.s*" $(seq $((22-${#testname}))))

		echo "*** Log file content (./$testname/$logname): $bar"
		echo "------------------------------------------------------------------"
		cat "./$testname/$logname"
		echo ""
	done <<< "$(tail --lines=+2 report.log)"

	if [[ $printcount = 0 ]];
	then
		echo "No tests failed during the last run of the testsuite."
	fi

	exit 0
fi

# We need at least the config file.
if [[ ${#} -lt 1 ]]; then
	usage
	exit 1
fi

while getopts ":lf" Option;
do
	case $Option in
		f )
			FORCE=ON
		;;
		l )
			LOUD=ON
		;;
		\? )
			usage
			exit 1
		;;
	esac
done
shift $(($OPTIND - 1))

CONFIGFILE="$1"
shift

if [ -z "${CONFIGFILE}" ]
then
	echo "Error: You must specify a config file."
	usage
	exit 1
elif [ ! -e "${CONFIGFILE}" ]
then
	echo "Error: Can't access \"${CONFIGFILE}\"."
	exit 1
fi

# creating a file that will hold the AT_* vars
# scripts that need to use any of the AT_* vars can
# access them by calling:
# array set AT_ENV [ exec cat envvararray.txt ]
# i.e. $AT_ENV(AT_DEST)
#
source $CONFIGFILE
set > envtempfile.txt
grep "AT_" envtempfile.txt | sed 's/^> //' | sed "s/'/{/" | \
	sed "s/'/}/"| sed 's/=/!!!/' > envvars.txt
while read line
do
	varname=""
	varval=""
	varname=$(echo $line | awk -F'!!!' '{ print $1 }')
	varval=$(echo $line |  awk -F'!!!' '{ print $2 }')
	if [ ${#varval} -eq 0 ]
	then
		varval="NOT_SET"
	fi
	export $varname="$varval"
done < envvars.txt

if [ -e "${AT_WD}" ]
then
	export AT_WD=$AT_WD
fi

export PATH=${AT_DEST}/bin:${PATH}

if [ $LOUD = "OFF" ]
then
	DIRECTOUTPUT=$(date +%Y%m%d)"fvtr.log"
	if [ -e "$DIRECTOUTPUT" ]
	then
		rm "$DIRECTOUTPUT"
	fi

	if [ -e "report.log" ]
	then
		rm "report.log"
	fi

	# In case logs are being generated for each test,
	# we create a file to save results of all tests,
	# so fvtr.sh can know, when it is later called,
	# which tests failed
	echo "$DIRECTOUTPUT" >> report.log
else
	DIRECTOUTPUT="stdout"
fi

# Create a file to hold the auxv info.
# Scripts can read if they need any system info.
LD_SHOW_AUXV=1 /bin/true > auxv_info.txt

PLATFORM="$(grep AT_PLATFORM auxv_info.txt |  awk -F':' '{print $2}' \
	    | sed 's/^ *//')"

rdot='.'
rslash='/'
if [ $# -eq 0 ]
then
	runall
else
	isall="$(tr [A-Z] [a-z] <<< "$1")"
	if [ $isall = 'all' ]
	then
		runall
	else
		TESTS2RUN=$@
	fi
fi

total_passed=0
total_ignored=0
total_failed=0

for i in $TESTS2RUN
do
	if [ -e "./"$i"/"$i".exp" ]
	then
		# Do not run a testcase if it has already been run (a log file
		# is available).
		if ! ls ./${i}/*fvtr.log &> /dev/null || [ $FORCE = "ON" ]
		then
			# Always print $PLATFORM at char position 25.
			# As it's necessary to add a space between the name of
			# the testcase and $PLATFORM, that leaves 23 characters
			# for the name of the testcase, aka $i.  The tab size
			# is 8.
			ind_level=$(expr \( 23 - ${#i} \) / 8 + 1)
			indent=""
			while [[ ${ind_level} -gt 0 ]]
			do
				indent="${indent}\t"
				ind_level=$(expr ${ind_level} - 1)
			done
			# Limit the name of the testcase in 23 characters.
			echo -ne "${i:0:23}${indent}$PLATFORM: "

			"./"$i"/"$i".exp" $i $DIRECTOUTPUT $PLATFORM
			rc=$?
			case "$rc" in
				"0")
					echo -e "\tpassed"
					total_passed=$(expr ${total_passed} + 1) ;;
				"38")
					echo -e "\tignored"
					total_ignored=$(expr ${total_ignored} + 1) ;;
				*)
					echo -e "\tfailed"
					total_failed=$(expr ${total_failed} + 1)

					if [[ $LOUD = "OFF" ]];
					then
						echo -e "$i\tfailed" >> report.log
					fi

					ret=1 ;;
			esac
		else
			echo "$i test already run.  Use the -f option to" \
			     "force it to run."
		fi
	fi
done

echo ""
echo "**************** TEST SUMMARY *****************"
echo "Passed tests: ${total_passed}"
echo "Skipped tests: ${total_ignored}"
echo "Failed tests: ${total_failed}"
echo "***********************************************"

# clean up
if [ -e auxv_info.txt ]
then
	rm auxv_info.txt
fi
if [ -e envvars.txt ]
then
	rm envvars.txt
fi
if [ -e envtempfile.txt ]
then
	rm envtempfile.txt
fi

exit $ret
