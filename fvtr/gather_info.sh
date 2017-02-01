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

# Gather information from system

LOG="sysinfo.log"

{
	echo "---= Distribution info =---"
	find /etc/ -maxdepth 1 -type f -name '*release' | xargs cat

	echo
	echo -e "---= Kernel info: =---"
	uname -a

	echo
	echo -e "---= CPU info: =---"
	cat /proc/cpuinfo

	echo
	echo -e "---= Memory info: =---"
	cat /proc/meminfo
} > ${LOG}
