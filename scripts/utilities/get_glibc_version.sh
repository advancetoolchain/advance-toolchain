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

# Identify glibc version by parsing the output of the C preprocessor after
# reading glibc header features.h.

CC=${CC:-$(which gcc)}

echo '#include <features.h>' | ${CC}  -dM -E - \
	| awk '/#define __GLIBC__/ { gmajor = $3 } \
	       /#define __GLIBC_MINOR__/ { gminor = $3 } \
	       END { print gmajor"."gminor }'


if [[ ${PIPESTATUS[1]} -ne 0 || ${PIPESTATUS[2]} -ne 0 ]]; then
	exit 1
fi

exit 0
