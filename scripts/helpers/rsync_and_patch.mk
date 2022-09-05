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
# FUNCTION: rsync_and_patch
#
#	This function does several things.  It rsyncs @1 into @2.  It then applies
#	every patch in @3 to @2.  Finally it untars all tars in @4 into @2.  The
#	parameters @3 and @4 can be empty strings i.e. "" if there are no patches
#	or tars to apply.
#
# Parameters:
#
#	@1 Location of the source to be copied
#		e.g "/home/$USER/at-build/sources/gcc-4.1-20060628"
#
#	@2 Destination where the source is to be copied
#		e.g. "/home/$USER/at-build/at13.0/src/gcc"
#
#	@3 Location of the patch files to be copied or "" (null)
#		e.g "/home/$USER/at-build/patches"
#
#	@4 Patch level tokens followed by fully qualified paths, space delimited or
#	   "" (null)
#		e.g. "-p1 /home/$USER/at-build/patches/gcc-4.1-power5.patch -p0 /home/$USER/at-build/patches/gcc-4.1-power4.patch"
#
#	@5 Fully qualified path to tar files, space delimited or ""
#		e.g. "/home/$USER/at-build/patches/glibc-powerpc-cpu-addon-v0.02.tgz"
#
#	@6 Parameter to flag a complete delete of the source
#

define rsync_and_patch
    [[ -n $${DEBUG} ]] && set -ex; \
    src_path=$1; \
    dest_path=$2; \
    patch_path=$3; \
    patch_list=$4; \
    tar_list=$5; \
    delete=$6; \
    if [[ -z $${src_path} ]] || [[ -z $${dest_path} ]]; then \
        echo "rsync_and_patch invoked without required parameters... Aborting!"; \
        exit 1; \
    fi; \
    if [[ ! -n "$${src_path}" ]]; then \
        echo "Couldn't find source at $${src_path}"; \
        exit 1; \
    fi; \
    mkdir -p $${dest_path}; \
    echo "rsync -rptlgo $${delete:+--delete} --exclude=CVS --exclude=.svn --exclude=.git\* --exclude=\*~ --exclude=.\* \"$${src_path}/\" \"$${dest_path}\""; \
    rsync -rptlgo $${delete:+--delete} --exclude=CVS --exclude=.svn --exclude=.git\* --exclude=\*~ --exclude=.\* "$${src_path}/" "$${dest_path}"; \
    if [[ $${?} -ne 0 ]]; then \
        echo "rsync of $${src_path} to $${dest_path} failed!"; \
        exit 1; \
    fi; \
    echo "rsync of $${src_path} to $${dest_path} successful"; \
    patch_level=""; \
    patch=""; \
    for tar in $${tar_list}; do \
        cp -v $${patch_path}/$${tar} $${dest_path}/; \
        filetype=$$(echo $${tar} | grep "bz2" | sed "s/^.*\.bz2/bz2/"); \
        if [[ "$${filetype}" == "bz2" ]]; then \
            cd $${dest_path}; \
            tar -xvjf $${tar}; \
            if [[ $${?} -ne 0 ]]; then \
                echo "  tar -xvjf $${tar} failed!"; \
                exit 1; \
            fi; \
            echo "  tar -xvzf $${tar} was successful"; \
        else \
            cd $${dest_path}; \
            tar -xvzf $${tar}; \
            if [[ $${?} -ne 0 ]]; then \
                echo "  tar -xvjf $${tar} failed!"; \
                exit 1; \
            fi; \
            echo "  tar -xvzf $${tar} was successful"; \
        fi; \
    done; \
    if [[ -n $${delete} ]]; then \
        for token in $${patch_list}; do \
            if [[ -z $${patch_level} ]]; then \
                patch_level=$$(echo $${token} | tr _ " "); \
                patch=""; \
                continue; \
            fi; \
            patch="$${token}"; \
            if [[ ! -e "$${dest_path}/$${patch}" ]]; then \
                echo "  preparing patch $${patch_path}/$${patch}..."; \
                cp -v $${patch_path}/$${patch} $${dest_path}/; \
            fi; \
            cd $${dest_path}; \
            patch $${patch_level} < $${patch}; \
            if [[ $${?} -ne 0 ]]; then \
                echo "  patch $${patch_level} < $${patch} failed!"; \
                exit 1; \
            fi; \
            echo "  patch $${patch_level} < $${patch} successful"; \
            patch_level=""; \
        done; \
    fi; \
    unset -v src_path \
             dest_path \
             patch_path \
             patch_list \
             tar_list \
             delete; \
    [[ -n $${DEBUG} ]] && set +ex || echo
endef
