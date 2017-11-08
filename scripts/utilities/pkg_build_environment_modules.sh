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
#
# File: pkg_build_environment_modules
#
# Description
#   Create environment modules file(s)
#   - Create simple module file for basic Advance Toolchain, setting PATHs
#   - Create module for cross, setting aliases for cross commands
#
# Parameters
AT_DEST="$1"
AT_DIR_NAME="$2"
TARGET="$3"
filelist="$4"
CROSS_BUILD="$5"
#

mkdir -p "$AT_DEST/share/modules/modulefiles"

# Create simple module file for basic Advance Toolchain
cat >"$AT_DEST/share/modules/modulefiles/$AT_DIR_NAME" <<EOF
#%Module1.0
set AT_VERSION "$AT_DIR_NAME"
proc ModulesHelp { } {
	global AT_VERSION
	puts stderr "Environment for using IBM Advance Toolchain \$AT_VERSION"
}
module-whatis "Environment for using IBM Advance Toolchain \$AT_VERSION"

prepend-path PATH "$AT_DEST/bin"
prepend-path INFOPATH "$AT_DEST/share/info"
prepend-path MANPATH "$AT_DEST/share/man"
EOF

# Add module file to packaging file list
echo "$AT_DEST/share/modules/modulefiles/$AT_DIR_NAME" > "$filelist"

if [ "$CROSS_BUILD" = "yes" ]; then

	# Create module file for cross compilation environment
	cat >"$AT_DEST/share/modules/modulefiles/$AT_DIR_NAME-$TARGET" <<EOF
#%Module1.0
set AT_VERSION "$AT_DIR_NAME"
proc ModulesHelp { } {
	global AT_VERSION
	puts stderr "Environment for using IBM Advance Toolchain \$AT_VERSION cross-compiler"
	puts stderr "Sets up environment variables and aliases to facilitate transparent use of the IBM Advance Toolchain \$AT_VERSION cross-compiler."
	puts stderr "Use with extreme care, as newly created executables will not execute natively!  (Don't rebuild /bin/init!)"
}
module-whatis "Environment for using IBM Advance Toolchain \$AT_VERSION cross-compiler"

set MODE "[module-info mode]"

if {[is-loaded "\$AT_VERSION"]} {
	if {"\$MODE" == "remove"} {
		module unload "\$AT_VERSION"
	}
} else {
	if {"\$MODE" == "load"} {
		module load "\$AT_VERSION"
	}
}

EOF
	# Add aliases for cross compilation environment commands
	{
		for file in $(ls -1 "$AT_DEST/bin/$TARGET-"* 2>/dev/null); do
			file=$(basename "$file")
			echo "set-alias ${file#"$TARGET-"} $file"
		done
	} >>"$AT_DEST/share/modules/modulefiles/$AT_DIR_NAME-$TARGET"

	# Add module file to packaging file list
	echo "$AT_DEST/share/modules/modulefiles/$AT_DIR_NAME-$TARGET" >> "$filelist"
fi

