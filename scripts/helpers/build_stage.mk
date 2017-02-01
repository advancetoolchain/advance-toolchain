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
# FUNCTION: build_stage
#
#	This function basically builds the code on source $1 following directives
#	for stage $2 informed. It first clear the stage $2 build (if present) and
#	then recreate the build.
#
# Used globals:
#	$(BUILD) Place where the build should happen (usually $(AT_WD)/builds)
#
# Parameters:
#
#	$1 Location of the source to use on the build
#		e.g "/home/$USER/at-build/at5.0/sources/gcc
#
#	$2 Kind of build stage to create (folder or symlink)
#		e.g. "dir" or "link"
#
#	$3 Numeric value for stage to build
#		e.g. 1, 2, 3,..., n
#

# Prepare the building area based on the rsync source folder and enter on it

define build_stage
    at_active_build=$(BUILD)/$$(basename $1)$${AT_BIT_SIZE}_$3; \
    echo "Recreating the build folder."; \
    if [[ -e $${at_active_build} ]]; then \
        rm -rf $${at_active_build}; \
    fi; \
    if [[ "$2" == "link" ]]; then \
        cp -r --preserve=mode,timestamps $1 $${at_active_build}; \
    else \
        mkdir $${at_active_build}; \
    fi; \
    pushd $${at_active_build}; \
    echo "Build stage $3, on $${at_active_build}..."
endef


# FUNCTION: build_stage2
#
#	This function basically builds the code on source $1 following
#	directives $2.  It first clear the build (if present) and then recreate
#	the build.
#
# Used globals:
#	$(BUILD) Place where the build should happen (usually $(AT_WD)/builds)
#
# Parameters:
#
#	$1 Location of the source to use on the build
#		e.g "/home/$USER/at-build/at5.0/sources/gcc
#
#	$2 Kind of build stage to create (folder or symlink)
#		e.g. "dir" or "link"
#
#	$3 Stage id
#		e.g. glibc32_2, kernel_h
#

# Prepare the building area based on the rsync source folder and enter on it
define build_stage2
    at_active_build=$(BUILD)/$3; \
    echo "Recreating the build folder."; \
    if [[ -e $${at_active_build} ]]; then \
        rm -rf $${at_active_build}; \
    fi; \
    if [[ "$2" == "link" ]]; then \
    cp -r --preserve=mode,timestamps,links --no-dereference \
       $1 $${at_active_build}; \
    else \
        mkdir $${at_active_build}; \
    fi; \
    pushd $${at_active_build}; \
    echo "Build stage $3, on $${at_active_build}..."
endef
