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
# FUNCTION: standard_buildf
#
#	This function basically builds the code on source $1 following directives
#	for stage $2 informed. It first clear the stage $2 build (if present) and
#	then recreate the build.
#
# Parameters:
#
#	$1 Location of the source to use on the build
#		e.g "/home/$USER/at-build/at5.0/sources/gcc
#
#	$2 Stage step to base your build on
#		e.g. 1
#
#	$3 Location of the root build place
#		e.g "/home/$USER/at-build/at5.0/builds"
#

define standard_buildf
    [[ -n $${DEBUG} ]] && set -ex; \
    set -x; \
    local_step=1; \
    local_log_prefix="$(LOGS)/_$${AT_STEPID}-3_standard_buildf-"; \
    install_place=$$(echo $(TEMP_INSTALL)/$${AT_STEPID} | sed 's|//*|/|g'); \
    install_transfer=$$(echo $(TEMP_INSTALL)/$${AT_STEPID}/$(AT_DEST) | sed 's|//*|/|g'); \
    if [[ -e $${install_place} ]]; then \
        rm -rf $${install_place}; \
        mkdir $${install_place}; \
    fi; \
    echo "Checking for pre build hacks."; \
    if [[ "x$$(type -t atcfg_pre_hacks)" == "xfunction" ]]; then \
        echo "Running pre build hacks."; \
        $(call runandlog,$${local_log_prefix}$$(printf "%.2d" $${local_step})_pre_build_hacks.log, eval atcfg_pre_hacks); \
        if [[ $${ret} -ne 0 ]]; then \
            echo "Problem running pre build hacks."; \
            exit 1; \
        fi; \
    fi; \
    local_step=$$(bc <<< $${local_step}+1); \
    echo "Begin the building process."; \
    echo "Checking for pre-configure settings and/or commands."; \
    if [[ "x$$(type -t atcfg_pre_configure)" == "xfunction" ]]; then \
        echo "Running pre-configure settings and/or commands."; \
        $(call runandlog,$${local_log_prefix}$$(printf "%.2d" $${local_step})_pre_configure.log,eval atcfg_pre_configure); \
        if [[ $${ret} -ne 0 ]]; then \
            echo "Problem running pre-configure commands."; \
            exit 1; \
        fi; \
    fi; \
    local_step=$$(bc <<< $${local_step}+1); \
    echo "Running the selected configure"; \
    $(call runandlog,$${local_log_prefix}$$(printf "%.2d" $${local_step})_configure.log,eval atcfg_configure); \
    if [[ $${ret} -ne 0 ]]; then \
        echo "Problem running configure command."; \
        exit 1; \
    fi; \
    local_step=$$(bc <<< $${local_step}+1); \
    echo "Checking for post-configure settings and/or commands."; \
    if [[ "x$$(type -t atcfg_post_configure)" == "xfunction" ]]; then \
        echo "Running post-configure settings and/or commands."; \
        $(call runandlog,$${local_log_prefix}$$(printf "%.2d" $${local_step})_post_configure.log,eval atcfg_post_configure); \
        if [[ $${ret} -ne 0 ]]; then \
            echo "Problem running post-configure commands."; \
            exit 1; \
        fi; \
    fi; \
    local_step=$$(bc <<< $${local_step}+1); \
    echo "Checking for pre-make settings and/or commands."; \
    if [[ "x$$(type -t atcfg_pre_make)" == "xfunction" ]]; then \
        echo "Running pre-make settings and/or commands."; \
        $(call runandlog,$${local_log_prefix}$$(printf "%.2d" $${local_step})_pre_make.log,eval atcfg_pre_make); \
        if [[ $${ret} -ne 0 ]]; then \
            echo "Problem running pre-make commands."; \
            exit 1; \
        fi; \
    fi; \
    local_step=$$(bc <<< $${local_step}+1); \
    echo "Running the selected make"; \
    $(call runandlog,$${local_log_prefix}$$(printf "%.2d" $${local_step})_make.log,eval atcfg_make); \
    if [[ $${ret} -ne 0 ]]; then \
        echo "Problem running make command."; \
        exit 1; \
    fi; \
    if [[ "x$$(type -t atsrc_package_verify_make_log)" == "xfunction" ]]; then \
        echo "Checking make log for $${AT_STEPID}"; \
        atsrc_package_verify_make_log "$${local_log_prefix}$$(printf "%.2d" $${local_step})_make.log"; \
        if [[ $${?} -ne 0 ]]; then \
            echo "Verify of make log failed"; \
            exit 1; \
        fi; \
    fi; \
    local_step=$$(bc <<< $${local_step}+1); \
    echo "Checking for unexpected behavior from configuration scripts"; \
    $(call runandlog,$${local_log_prefix}$$(printf "%.2d" $${local_step})_verify_unexpected_conf.log, verify_unexpected_conf); \
    if [[ $${ret} -ne 0 ]]; then \
        echo "Problem running tests for unexpected behavior from configuration scripts."; \
        exit 1; \
    fi; \
    local_step=$$(bc <<< $${local_step}+1); \
    echo "Checking for post-make settings and/or commands."; \
    if [[ "x$$(type -t atcfg_post_make)" == "xfunction" ]]; then \
        echo "Running post-make settings and/or commands."; \
        $(call runandlog,$${local_log_prefix}$$(printf "%.2d" $${local_step})_post_make.log,eval atcfg_post_make); \
        if [[ $${ret} -ne 0 ]]; then \
            echo "Problem running post-make commands."; \
            exit 1; \
        fi; \
    fi; \
    local_step=$$(bc <<< $${local_step}+1); \
    echo "Checking for make-check settings and/or commands."; \
    if [[ "x$$(type -t atcfg_make_check)" == "xfunction" ]]; then \
        make_check_value="none"; \
        if [[ "$${ATSRC_PACKAGE_MAKE_CHECK}" != "none" ]]; then \
            if [[ ("$${ATSRC_PACKAGE_MAKE_CHECK}" == "strict_fail") || \
                   ("$${ATSRC_PACKAGE_MAKE_CHECK}" == "silent_fail") ]]; then \
                make_check_value="$${ATSRC_PACKAGE_MAKE_CHECK}"; \
            elif [[ "$${AT_MAKE_CHECK}" == "strict_fail" || "$${AT_MAKE_CHECK}" == "silent_fail" ]]; then \
                make_check_value="$${AT_MAKE_CHECK}"; \
            fi; \
            if [[ "$${make_check_value}" != "none" ]]; then \
                echo "Running make-check settings and/or commands."; \
                if [[ -e "$${local_log_prefix}$$(printf "%.2d" $${local_step})_make_check.log" ]]; then \
                    cat "$${local_log_prefix}$$(printf "%.2d" $${local_step})_make_check.log" >> "$${local_log_prefix}$$(printf "%.2d" $${local_step})_make_check_history.log"; \
                    rm "$${local_log_prefix}$$(printf "%.2d" $${local_step})_make_check.log"; \
                fi; \
                $(call runandlog,$${local_log_prefix}$$(printf "%.2d" $${local_step})_make_check.log,eval atcfg_make_check); \
                if [[ $${ret} -eq 0 ]]; then \
                    if [[ "x$$(type -t atsrc_package_verify_make_check_log)" == "xfunction" ]]; then \
                        atsrc_package_verify_make_check_log "$${local_log_prefix}$$(printf "%.2d" $${local_step})_make_check.log"; \
                        if [[ $${?} -eq 0 ]]; then \
                            ret=1; \
                        fi; \
                    fi; \
                fi; \
                if [[ $${ret} -ne 0 ]]; then \
                    echo "Problem running make-check commands."; \
                    echo "$(AT_TODAY) AT$(AT_FULL_VER) FAIL $${AT_STEPID}" >> "$(LOGS)/at_package_testing.log"; \
                    if [[ "$${make_check_value}" == "strict_fail" ]]; then \
                        exit 1; \
                    else \
                        export ATCFG_HOLD_TEMP_BUILD=yes; \
                    fi; \
                else \
                    echo "$(AT_TODAY) AT$(AT_FULL_VER) PASS $${AT_STEPID}" >> "$(LOGS)/at_package_testing.log"; \
                fi; \
            fi; \
        fi; \
    fi; \
    local_step=$$(bc <<< $${local_step}+1); \
    echo "Checking for pre-install settings and/or commands."; \
    if [[ "x$$(type -t atcfg_pre_install)" == "xfunction" ]]; then \
        echo "Running pre-install settings and/or commands."; \
        $(call runandlog,$${local_log_prefix}$$(printf "%.2d" $${local_step})_pre_install.log,eval atcfg_pre_install); \
        if [[ $${ret} -ne 0 ]]; then \
            echo "Problem running pre-install commands."; \
            exit 1; \
        fi; \
    fi; \
    local_step=$$(bc <<< $${local_step}+1); \
    echo "Running the selected install"; \
    $(call runandlog,$${local_log_prefix}$$(printf "%.2d" $${local_step})_install.log,eval atcfg_install); \
    if [[ $${ret} -ne 0 ]]; then \
        echo "Problem running install command."; \
        exit 1; \
    fi; \
    local_step=$$(bc <<< $${local_step}+1); \
    echo "Checking for post-install settings and/or commands."; \
    if [[ "x$$(type -t atcfg_post_install)" == "xfunction" ]]; then \
        echo "Running post-install settings and/or commands."; \
        $(call runandlog,$${local_log_prefix}$$(printf "%.2d" $${local_step})_post_install.log,eval atcfg_post_install); \
        if [[ $${ret} -ne 0 ]]; then \
            echo "Problem running post-install commands."; \
            exit 1; \
        fi; \
    fi; \
    local_step=$$(bc <<< $${local_step}+1); \
    echo "Checking for post build hacks."; \
    if [[ "x$$(type -t atcfg_post_hacks)" == "xfunction" ]]; then \
        echo "Running post build hacks."; \
        $(call runandlog,$${local_log_prefix}$$(printf "%.2d" $${local_step})_post_build_hacks.log, eval atcfg_post_hacks); \
        if [[ $${ret} -ne 0 ]]; then \
            echo "Problem running post build hacks."; \
            exit 1; \
        fi; \
    fi; \
    if [[ "$${ATCFG_INSTALL_PEDANTIC}" == "no" && (( ! -d "$${install_transfer}" )) ]]; then \
        echo "No pedantic install on inexistent $${install_transfer}, please check the previous logs for potential errors."; \
    elif [[ (( -z $${ATCFG_INSTALL_PEDANTIC} || "$${ATCFG_INSTALL_PEDANTIC}" == "yes" )) && (( ! -d "$${install_transfer}" )) ]]; then \
        echo "Pedantic install required, but inexistent $${install_transfer}. Aborting stage!"; \
        exit 1; \
    else \
        echo "Collect file paths installed."; \
        $(call collect_filelist,$(DYNAMIC_SPEC)/$${ATSRC_PACKAGE_BUNDLE}/$${AT_STEPID}.filelist,$${install_transfer},$(AT_DEST)); \
        if [[ "$(BUILD_DEBUG_ON)" != "yes" ]]; then \
            if [[ "$${ATCFG_HOLD_TEMP_INSTALL}" != "yes" ]]; then \
                echo "Removing files from $${install_place}."; \
                rm -rf $${install_place}; \
            fi; \
        fi; \
        echo "Looking for broken symlinks."; \
        broken_links=$(find . -type l -! -exec test -e {} \; -print); \
        if [[ -n "${broken_links}" ]]; then \
            echo -e "The following symlinks are broken:\n${broken_links}"; \
            exit 1; \
        fi; \
    fi; \
    local_step=$$(bc <<< $${local_step}+1); \
    echo "Checking for post install hacks."; \
    if [[ "x$$(type -t atcfg_posti_hacks)" == "xfunction" ]]; then \
        echo "Running post install hacks."; \
        $(call runandlog,$${local_log_prefix}$$(printf "%.2d" $${local_step})_post_install_hacks.log, eval atcfg_posti_hacks); \
        if [[ $${ret} -ne 0 ]]; then \
            echo "Problem running post install hacks."; \
            exit 1; \
        fi; \
    fi; \
    echo -ne "Getting back to: "; popd; \
    [[ -n $${DEBUG} ]] && set +ex || echo
endef
