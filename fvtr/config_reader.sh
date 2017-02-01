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
# Processes and prints all variables in the config file specified at $1
#

file1=`mktemp`
file2=`mktemp`

set > $file1

source $1

set > $file2

diff $file1 $file2 | grep ">" | grep "AT_" | awk '{ print $2 }'

rm $file1 $file2
