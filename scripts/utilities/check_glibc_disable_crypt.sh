#!/bin/bash
#
# Copyright 2022 IBM Corporation
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

# Check if it´s needed to compile glibc´s libcrypt.
# If libxcrypt is available in OS, glibc´s libcrypt will not be compiled.
# Except in cross build. In this case, glibc's libcrypt must be compiled
# because it´s required to build gcc

if [[ "${cross_build}" == "no" ]]; then

        libcrypt_folder="/usr/lib/powerpc64le-linux-gnu"
        if [[ ! -d $libcrypt_folder ]]; then
                libcrypt_folder="/usr/lib64"
        fi

        libfiles=$(find  ${libcrypt_folder} -name 'libcrypt.so*')

        for file_crypt in ${libfiles};do
                if [[ $(readelf -a ${file_crypt} | grep -c 'XCRYPT') -ne 0 ]]; then
                        echo "yes"
                        break
                fi
        done
fi

exit 0

