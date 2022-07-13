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
# Helper macro functions
#
#
#
#
#
#
#
#
#
#
#
#
#

#
#
#
# Ex: $(call get_distro_info)
define get_distro_info
    distro_rawname=$$($(LSBTOOL) -i | cut -d":" -f 2 | sed "s/^[ \t]*//" | tr [:upper:] [:lower:]); \
    distro_rawid=$$($(LSBTOOL) -r | cut -d":" -f 2 | sed "s/^[ \t]*//" | cut -d"." -f 1); \
    case $${distro_rawname} in \
        redhat*) \
            distro_name=redhat; \
            distro_abbrev="RHEL$${distro_rawid}"; \
            ;; \
        centos*) \
            distro_name=centos; \
            distro_abbrev=""; \
            ;; \
        suse*) \
            distro_name=suse; \
            distro_abbrev="SLES$${distro_rawid}"; \
            ;; \
        opensuse*) \
            distro_name=opensuse; \
            distro_abbrev=""; \
            ;; \
        fedora*) \
            distro_name=fedora; \
            distro_abbrev=""; \
            ;; \
        ubuntu*) \
            distro_name=ubuntu; \
            distro_abbrev=""; \
            ;; \
        debian*) \
            distro_name=debian; \
            distro_abbrev=""; \
            ;; \
        *) \
            distro_name=unknown; \
            distro_abbrev=""; \
            ;; \
    esac; \
    echo "$${distro_name}-$${distro_rawid} $${distro_abbrev}"
endef


#
#
#
#
# Ex: $(call start_debug)
define start_debug
    [[ -n $${DEBUG} ]] && set -x
endef


#
#
#
#
# Ex: $(call end_debug)
define end_debug
    set +x
endef


#
#
#
#
# Ex: $(call remove_tmpbuild)
define remove_tmpbuild
    pushd $(TEMP_INSTALL); \
    folders=$$(find . -type d -print | sed '/^.$$/d'); \
    if [[ -z "$${folders}" ]]; then \
        echo "Cleaning all build stage..."; \
        rm -rf $(TEMP_INSTALL); \
    else \
        echo "Remaining install folders present..."; \
    fi; \
    popd
endef


# Build the environment variables needed by our basic build functions
#
#
# Ex: $(call std_setenv)
define std_setenv
    echo "* Preparing standard build env variables."; \
    echo "  - Setting host to $(HOST)"; \
    export host=$(HOST); \
    echo "  - Setting at_dest to $(AT_DEST)"; \
    export at_dest=$(AT_DEST); \
    echo "  - Setting at_base to $(AT_BASE)"; \
    export at_base=$(AT_BASE); \
    echo "  - Setting at_name to $(AT_NAME)"; \
    export at_name=$(AT_NAME); \
    echo "  - Setting destdir to $(DESTDIR)"; \
    export destdir=$(DESTDIR); \
    echo "  - Setting at_major_version to $(AT_MAJOR_VERSION)"; \
    export at_major_version=$(AT_MAJOR_VERSION); \
    echo "  - Setting at_major_internal to $(AT_MAJOR_INTERNAL)"; \
    export at_major_internal=$(AT_MAJOR_INTERNAL); \
    echo "  - Setting at_full_ver to $(AT_FULL_VER)"; \
    export at_full_ver=$(AT_FULL_VER); \
    echo "  - Setting at_revision_number to $(AT_REVISION_NUMBER)"; \
    export at_revision_number=$(AT_REVISION_NUMBER); \
    echo "  - Setting at_internal to $(AT_INTERNAL)"; \
    export at_internal=$(AT_INTERNAL); \
    echo "  - Setting at_ver_rev_internal to $(AT_VER_REV_INTERNAL)"; \
    export at_ver_rev_internal=$(AT_VER_REV_INTERNAL); \
    echo "  - Setting at_dir_name to $(AT_DIR_NAME)"; \
    export at_dir_name=$(AT_DIR_NAME); \
    echo "  - Setting at_end_of_life to $(AT_END_OF_LIFE)"; \
    export at_end_of_life=$(AT_END_OF_LIFE); \
    echo "  - Setting at_use_fedora_relnam to $(AT_USE_FEDORA_RELNAM)"; \
    export at_use_fedora_relnam=$(AT_USE_FEDORA_RELNAM); \
    echo "  - Setting kernel to $(AT_KERNEL)"; \
    export kernel=$(AT_KERNEL); \
    echo "  - Setting compat_kernel to $(AT_OLD_KERNEL)"; \
    export compat_kernel=$(AT_OLD_KERNEL); \
    echo "  - Setting number of cores num_cores to $(NUM_CORES)"; \
    export num_cores=$(NUM_CORES); \
    echo "  - Setting logs to $(LOGS)"; \
    export logs=$(LOGS); \
    echo "  - Setting config to $(CONFIG)"; \
    export config=$(CONFIG); \
    echo "  - Setting sources to $(SOURCE)"; \
    export sources=$(SOURCE); \
    echo "  - Setting builds to $(BUILD)"; \
    export builds=$(BUILD); \
    echo "  - Setting dest_cross to $(DEST_CROSS)"; \
    export dest_cross=$(DEST_CROSS); \
    echo "  - Setting scripts to $(SCRIPTS_ROOT)"; \
    export scripts=$(SCRIPTS_ROOT); \
    echo "  - Setting skeletons to $(SKELETONS_ROOT)"; \
    export skeletons=$(SKELETONS_ROOT); \
    echo "  - Setting script helpers to $(SCRIPTS_ROOT)/utilities"; \
    export utilities=$(SCRIPTS_ROOT)/utilities; \
    echo "  - Setting dynamic_spec to $(DYNAMIC_SPEC)"; \
    export dynamic_spec=$(DYNAMIC_SPEC); \
    echo "  - Setting config_spec to $(CONFIG_SPEC)"; \
    export config_spec=$(CONFIG_SPEC); \
    echo "  - Setting the temporary instalation directory to '$(TEMP_INSTALL)'"; \
    export tmp_dir=$(TEMP_INSTALL); \
    echo "  - Setting the installation directory for cross to '$(TEMP_INSTALL)/$${AT_STEPID}/$(DEST_CROSS)'"; \
    export install_transfer_cross=$(TEMP_INSTALL)/$${AT_STEPID}/$(DEST_CROSS); \
    echo "  - Setting at_supported_distros to $(AT_SUPPORTED_DISTROS)"; \
    export at_supported_distros="$(AT_SUPPORTED_DISTROS)"; \
    echo "* Finished standard env variables."
endef


# Build the environment variables needed by the build stage script functions
#
#
#
# Ex: $(call build_setenv)
define build_setenv
    $(call std_setenv); \
    echo "* Preparing build env variables."; \
    echo "  - Setting secure_plt to $(SECURE_PLT)"; \
    export secure_plt=$(SECURE_PLT); \
    echo "  - Setting default_cpu to $(DEFAULT_CPU)"; \
    export default_cpu=$(DEFAULT_CPU); \
    echo "  - Setting header_target to $(HEADER_TARGET)"; \
    export header_target=$(HEADER_TARGET); \
    echo "  - Setting header_target64 to $(HEADER_TARGET64)"; \
    export header_target64=$(HEADER_TARGET64); \
    echo "  - Setting target to $(TARGET)"; \
    export target=$(TARGET); \
    echo "  - Setting alternate_target to $(ALTERNATE_TARGET)"; \
    export alternate_target=$(ALTERNATE_TARGET); \
    echo "  - Setting target32 to $(TARGET32)"; \
    export target32=$(TARGET32); \
    echo "  - Setting target64 to $(TARGET64)"; \
    export target64=$(TARGET64); \
    echo "  - Setting compiler to $(COMPILER)"; \
    export compiler=$(COMPILER); \
    echo "  - Setting env_build_arch to $(ENV_BUILD_ARCH)"; \
    export env_build_arch=$(ENV_BUILD_ARCH); \
    echo "  - Setting system_cc to $(SYSTEM_CC)"; \
    export system_cc="$(SYSTEM_CC)"; \
    echo "  - Setting system_cxx to $(SYSTEM_CXX)"; \
    export system_cxx="$(SYSTEM_CXX)"; \
    echo "  - Setting autoconf to $(AUTOCONF)"; \
    export autoconf="$(AUTOCONF)"; \
    echo "  - Setting default_compiler to $(DEFAULT_COMPILER)"; \
    export default_compiler=$(DEFAULT_COMPILER); \
    echo "  - Setting at_build_cpu to $(AT_BUILD_CPU)"; \
    export at_build_cpu=$(AT_BUILD_CPU); \
    echo "  - Setting build_arch to $(BUILD_ARCH)"; \
    export build_arch=$(BUILD_ARCH); \
    echo "  - Setting host_arch to $(HOST_ARCH)"; \
    export host_arch=$(HOST_ARCH); \
    echo "  - Setting cross_build to $(CROSS_BUILD)"; \
    export cross_build=$(CROSS_BUILD); \
    echo "  - Setting build_load_arch to $(BUILD_LOAD_ARCH)"; \
    export build_load_arch=$(BUILD_LOAD_ARCH); \
    echo "  - Setting build_base_arch to $(BUILD_BASE_ARCH)"; \
    export build_base_arch=$(BUILD_BASE_ARCH); \
    echo "  - Setting auxiliary gcc gcc64 to $(SCRIPTS_ROOT)/gcc64"; \
    export gcc64=$(SCRIPTS_ROOT)/gcc64; \
    echo "  - Setting auxiliary g++ gpp64 to $(SCRIPTS_ROOT)/g++64"; \
    export gpp64=$(SCRIPTS_ROOT)/g++64; \
    echo "  - Setting distribution distro_fm to $(DISTRO_FM)"; \
    export distro_fm=$(DISTRO_FM); \
    echo "  - Setting packaging system pack_sys to $(pack-sys)"; \
    export pack_sys=$(pack-sys); \
    echo "  - Setting with_longdouble to $(BUILD_WITH_LONGDOUBLE)"; \
    export with_longdouble=$(BUILD_WITH_LONGDOUBLE); \
    echo "  - Setting build_with_dfp_standalone to $(BUILD_WITH_DFP_STANDALONE)"; \
    export build_with_dfp_standalone=$(BUILD_WITH_DFP_STANDALONE); \
    if [[ -n "$(DISABLE_MULTILIB)" ]]; then \
        echo "  - Setting disable_multilib to yes"; \
        export disable_multilib=yes; \
    fi; \
    echo "  - Setting build_optimization to $(BUILD_OPTIMIZATION)"; \
    export build_optimization="$(BUILD_OPTIMIZATION)"; \
    echo "  - Setting build_gcc_languages to $(BUILD_GCC_LANGUAGES)"; \
    export build_gcc_languages=$(BUILD_GCC_LANGUAGES); \
    echo "  - Setting build_ignore_compat to $(BUILD_IGNORE_COMPAT)"; \
    export build_ignore_compat=$(BUILD_IGNORE_COMPAT); \
    echo "  - Setting build_ignore_at_compat to $(BUILD_IGNORE_AT_COMPAT)"; \
    export build_ignore_at_compat=$(BUILD_IGNORE_AT_COMPAT); \
    echo "  - Setting build_old_at_version to $(BUILD_OLD_AT_VERSION)"; \
    export build_old_at_version=$(BUILD_OLD_AT_VERSION); \
    echo "  - Setting build_old_at_install to $(BUILD_OLD_AT_INSTALL)"; \
    export build_old_at_install=$(BUILD_OLD_AT_INSTALL); \
    echo "  - Setting distro suppoted java versions to '$(AT_JAVA_VERSIONS)'"; \
    export java_versions="$(AT_JAVA_VERSIONS)"; \
    echo "  - Setting make check to '$(AT_MAKE_CHECK)'"; \
    export make_check="$(AT_MAKE_CHECK)"; \
    echo "* Finished build env variables."
endef


# Build the environment variables needed by the RPM pkg build functions
#
#
# Ex: $(call rpm_setenv)
define rpm_setenv
    $(call build_setenv); \
    echo "* Preparing rpm env variables."; \
    echo "  - Setting rpms to $(RPMS)"; \
    export rpms="$(RPMS)"; \
    echo "  - Setting rpm_build_type to $(BUILD_RPMS)"; \
    export rpm_build_type="$(BUILD_RPMS)"; \
    echo "  - Setting build_rpm_packager to $(BUILD_RPM_PACKAGER)"; \
    export build_rpm_packager="$(BUILD_RPM_PACKAGER)"; \
    echo "  - Setting build_rpm_vendor to $(BUILD_RPM_VENDOR)"; \
    export build_rpm_vendor="$(BUILD_RPM_VENDOR)"; \
    echo "  - Setting at_sign_repo to $(AT_SIGN_REPO)"; \
    export at_sign_repo="$(AT_SIGN_REPO)"; \
    echo "  - Setting at_sign_repo_cross to $(AT_SIGN_REPO_CROSS)"; \
    export at_sign_repo_cross="$(AT_SIGN_REPO_CROSS)"; \
    echo "  - Setting at_sign_pkgs to $(AT_SIGN_PKGS)"; \
    export at_sign_pkgs="$(AT_SIGN_PKGS)"; \
    echo "  - Setting at_sign_pkgs_cross to $(AT_SIGN_PKGS_CROSS)"; \
    export at_sign_pkgs_cross="$(AT_SIGN_PKGS_CROSS)"; \
    echo "  - Setting at_gpg_keyid to $(AT_GPG_KEYID)"; \
    export at_gpg_keyid="$(AT_GPG_KEYID)"; \
    echo "  - Setting at_gpg_keyidc to $(AT_GPG_KEYIDC)"; \
    export at_gpg_keyidc="$(AT_GPG_KEYIDC)"; \
    echo "  - Setting at_gpg_keyidl to $(AT_GPG_KEYIDL)"; \
    export at_gpg_keyidl="$(AT_GPG_KEYIDL)"; \
    echo "  - Setting at_gpg_repo_keyid to $(AT_GPG_REPO_KEYID)"; \
    export at_gpg_repo_keyid="$(AT_GPG_REPO_KEYID)"; \
    echo "  - Setting at_gpg_repo_keyidc to $(AT_GPG_REPO_KEYIDC)"; \
    export at_gpg_repo_keyidc="$(AT_GPG_REPO_KEYIDC)"; \
    echo "  - Setting at_gpg_repo_keyidl to $(AT_GPG_REPO_KEYIDL)"; \
    export at_gpg_repo_keyidl="$(AT_GPG_REPO_KEYIDL)"; \
    echo "  - Setting at_compat_distros to $(AT_COMPAT_DISTROS)"; \
    export at_compat_distros="$(AT_COMPAT_DISTROS)"; \
    echo "  - Setting distro_id to $(DISTRO_ID)"; \
    export distro_id="$(DISTRO_ID)"; \
    echo "  - Setting src_tar_file to $(SRC_TAR_FILE)"; \
    export src_tar_file="$(SRC_TAR_FILE)"; \
    echo "  - Setting relnot_file to $(RELNOT_FILE)"; \
    export relnot_file="$(RELNOT_FILE)"; \
    echo "  - Setting at_repocmd_opts to $(AT_REPOCMD_OPTS)"; \
    export at_repocmd_opts="$(AT_REPOCMD_OPTS)"; \
    echo "  - Setting build_exclusive_cross to $(BUILD_EXCLUSIVE_CROSS)"; \
    export build_exclusive_cross="$(BUILD_EXCLUSIVE_CROSS)"; \
    echo "* Finished rpm env variables."
endef


# Build the environment variables needed by the DEB pkg build functions
#
#
# Ex: $(call deb_setenv)
define deb_setenv
    $(call build_setenv); \
    echo "* Preparing deb env variables."; \
    echo "  - Setting debh_root to $(DEBH_ROOT)"; \
    export debh_root=$(DEBH_ROOT); \
    echo "  - Setting debs to $(DEBS)"; \
    export debs="$(DEBS)"; \
    echo "  - Setting use_systemd to $(USE_SYSTEMD)"; \
    export use_systemd="$(USE_SYSTEMD)"; \
    echo "* Finished deb env variables."
endef


#
#
#
# Ex: $(call collect_filelist,<filelist_path>,<actual_root>,<new_root>)
define collect_filelist
    echo "Validate the existence of the final filelist folder."; \
    if [[ ! -d "$$(dirname $1)" ]]; then \
        mkdir -p $$(dirname $1); \
    fi; \
    echo "Collecting installed files and links."; \
    find $2 -type f -print > $1; \
    find $2 -type l -print >> $1; \
    echo "Fixing the paths on the final file list"; \
    cat $1 | sort -u | \
        sed "s|$2|$3|g" > $1.seg; \
    mv $1.seg $1; \
    echo "Moving them to final position."; \
    rsync -aH $2/ $3; \
    if [[ $${?} -ne 0 ]]; then \
        echo "Found a problem copying to final destination... aborting!"; \
        exit 1; \
    fi; \
    echo "Completed installed files and links collection."
endef


#
#
#
# Created the AT ld.so.conf file
# Ex: $(call prepare_loader_cache)
#
# Although Ubuntu and Debian support multiarch libraries, many packages are
# still distributed in /lib or /usr/lib instead of the correct multiarch
# directory.  So, it's necessary to carry a hack until they complete to port
# all packages to multiarch.
#
# Another hack below is the "glibc-hwcaps" directory.
# During the build, there is an awkward period where some packages are
# built depending on AT libraries, but optimized libraries are not yet
# built. The loader will always prefer optimized libraries *even if they
# are under directories lower in the search order*.  For example,
# /lib64/power9/libc.so is preferred over /opt/atX.0/lib64/libc.so.
# This causes all sorts of problems during this awkward period.
# So, the glibc-hwcaps directory is put at the top of the search order
# and populated with AT-built (not-optimized) libraries in optimized
# subdirectories, so they will be used in preference, and the build
# can proceed through the awkward period.
# The glibc-hwcaps directory persists, with new optimized libraries
# gradually populating it as they are built/installed. Upon the second
# "ldconfig" pass, any files which have not been replaced by newly
# built, optimzed versions are removed.
define prepare_loader_cache
    set -e; \
    if [[ ! -d "$(AT_DEST)/etc/ld.so.conf.d" ]]; then \
        mkdir $(AT_DEST)/etc/ld.so.conf.d; \
    fi; \
    if [[ -n "$(TARGET32)" ]]; then \
        echo "$(AT_DEST)/$(TARGET)/lib"       >  "$(DYNAMIC_LOAD)/at32.ld.conf"; \
        echo "$(AT_DEST)/lib"                 >> "$(DYNAMIC_LOAD)/at32.ld.conf"; \
        echo "/lib"                           >  "$(DYNAMIC_LOAD)/sys32.ld.conf"; \
        echo "/usr/lib"                       >> "$(DYNAMIC_LOAD)/sys32.ld.conf"; \
        echo "/usr/local/lib"                 >> "$(DYNAMIC_LOAD)/sys32.ld.conf"; \
    fi; \
    if [[ -n "$(TARGET64)" ]]; then \
        > "$(DYNAMIC_LOAD)/at64.ld.conf"; \
        if [[ $1 -eq 1 ]]; then \
            echo "$(AT_DEST)/lib64/glibc-hwcaps"   >  "$(DYNAMIC_LOAD)/at64.ld.conf"; \
        fi; \
        echo "$(AT_DEST)/$(TARGET)/lib64" >> "$(DYNAMIC_LOAD)/at64.ld.conf"; \
        echo "$(AT_DEST)/lib64"           >> "$(DYNAMIC_LOAD)/at64.ld.conf"; \
        echo "/lib64"                     >  "$(DYNAMIC_LOAD)/sys64.ld.conf"; \
        if [[ ("$(DISTRO_FM)" == "ubuntu") || ("$(DISTRO_FM)" == "debian") ]]; then \
            echo "/lib/$(TARGET)"       >> "$(DYNAMIC_LOAD)/sys64.ld.conf"; \
            echo "/usr/lib/$(TARGET)"   >> "$(DYNAMIC_LOAD)/sys64.ld.conf"; \
            echo "/lib"                 >> "$(DYNAMIC_LOAD)/sys64.ld.conf"; \
            echo "/usr/lib"             >> "$(DYNAMIC_LOAD)/sys64.ld.conf"; \
        else \
            echo "/usr/lib64"                 >> "$(DYNAMIC_LOAD)/sys64.ld.conf"; \
            echo "/usr/local/lib64"           >> "$(DYNAMIC_LOAD)/sys64.ld.conf"; \
        fi; \
    fi; \
    if [[ $1 -ge 2 ]]; then \
        for CPU in $(TUNED_PROCESSORS); do \
            if [[ -n "$(TARGET32)" ]]; then \
                echo "$(AT_DEST)/lib/$${CPU}"       >> "$(DYNAMIC_LOAD)/at32.ld.conf"; \
            fi; \
            if [[ -n "$(TARGET64)" ]]; then \
                echo "$(AT_DEST)/lib64/$${CPU}" >> "$(DYNAMIC_LOAD)/at64.ld.conf"; \
            fi; \
        done; \
        echo "include /etc/ld.so.conf.d/*.conf" > "$(DYNAMIC_LOAD)/sysinc.ld.conf"; \
        echo "include $(AT_DEST)/etc/ld.so.conf.d/*.conf" > "$(DYNAMIC_LOAD)/atinc.ld.conf"; \
    fi; \
    if [[ -n "$(TARGET32)" && -n "$(TARGET64)" ]]; then \
        paste -d '\n' "$(DYNAMIC_LOAD)/at32.ld.conf" \
                      "$(DYNAMIC_LOAD)/at64.ld.conf" > "$(DYNAMIC_LOAD)/ld.so.conf"; \
    elif [[ -n "$(TARGET64)" ]]; then \
        cat "$(DYNAMIC_LOAD)/at64.ld.conf" > "$(DYNAMIC_LOAD)/ld.so.conf"; \
    else \
        cat "$(DYNAMIC_LOAD)/at32.ld.conf" > "$(DYNAMIC_LOAD)/ld.so.conf"; \
    fi; \
    [[ -f "$(DYNAMIC_LOAD)/atinc.ld.conf" ]] && \
                  cat "$(DYNAMIC_LOAD)/atinc.ld.conf" >> "$(DYNAMIC_LOAD)/ld.so.conf"; \
    if [[ -n "$(TARGET32)" && -n "$(TARGET64)" ]]; then \
        paste -d '\n' "$(DYNAMIC_LOAD)/sys32.ld.conf" \
                      "$(DYNAMIC_LOAD)/sys64.ld.conf" >> "$(DYNAMIC_LOAD)/ld.so.conf"; \
    elif [[ -n "$(TARGET64)" ]]; then \
        cat "$(DYNAMIC_LOAD)/sys64.ld.conf" >> "$(DYNAMIC_LOAD)/ld.so.conf"; \
    else \
        cat "$(DYNAMIC_LOAD)/sys32.ld.conf" >> "$(DYNAMIC_LOAD)/ld.so.conf"; \
    fi; \
    grep -E -v "^$$" "$(DYNAMIC_LOAD)/ld.so.conf" > "$(AT_DEST)/etc/ld.so.conf"; \
    if [[ $1 -eq 1 ]]; then \
        for cpu in $(BUILD_ACTIVE_MULTILIBS); do \
            mkdir -p $(AT_DEST)/lib64/glibc-hwcaps/"$${cpu}"; \
            (\cd $(AT_DEST)/lib64 && \
             find . -maxdepth 1 -type f \
                 -exec cp --preserve=mode,ownership '{}' \
                          $(AT_DEST)/lib64/glibc-hwcaps/"$${cpu}"/'{}' \; \
            ); \
        done; \
    fi; \
    "$(AT_DEST)/sbin/ldconfig"; \
    if [[ $1 -eq 1 ]]; then \
        touch "$(AT_DEST)/lib64/syslib-override"; \
    elif [[ $1 -eq 2 ]]; then \
        find "$(AT_DEST)/lib64/glibc-hwcaps" ! -type d \
             ! -newer "$(AT_DEST)/lib64/syslib-override" \
             -exec rm -f '{}' \;; \
        rm -f $(AT_DEST)/lib64/syslib-override; \
    fi; \
    group=$$( ls $(DYNAMIC_SPEC)/ | grep "toolchain\$$" ); \
    echo "$(AT_DEST)/etc/ld.so.conf" \
         >  $(DYNAMIC_SPEC)/$${group}/ldconfig.filelist; \
    echo "$(AT_DEST)/etc/ld.so.conf.d" \
         >> $(DYNAMIC_SPEC)/$${group}/ldconfig.filelist; \
    if [[ $1 -eq 2 ]]; then \
        if [[ "$(BUILD_IGNORE_COMPAT)" == "no" ]]; then \
            cp -rt $(AT_DEST)/compat/etc/ \
               $(AT_DEST)/etc/ld.so.conf.d $(AT_DEST)/etc/ld.so.conf; \
            echo "$(AT_DEST)/compat/etc/ld.so.conf" \
                 >  $(DYNAMIC_SPEC)/$${group}/ldconfig_compat.filelist; \
            echo "$(AT_DEST)/compat/etc/ld.so.conf.d" \
                 >> $(DYNAMIC_SPEC)/$${group}/ldconfig_compat.filelist; \
        fi; \
    fi; \
    set +e
endef


#
#
#
#
# Ex: $(call clean_stage)
define clean_stage
    if [[ -d $${at_active_build} ]]; then \
        at_base_scan=$$(echo $${at_active_build} | sed "s@$(AT_WD)/@./@g"); \
        cd $(AT_WD); \
        tar cf - $$({ { find $${at_base_scan} -type f -name 'config.[hlms]*' -print; \
                     find $${at_base_scan} -type f -name '*.log' -print; } \
                  | sort -u; }) | \
            tar xf - -C $(LOGS); \
        if [[ "$(BUILD_DEBUG_ON)" != "yes" ]]; then \
            [[ "$${ATCFG_HOLD_TEMP_BUILD}" == "yes" ]] || rm -rf $${at_active_build}; \
        fi; \
    fi
endef


#
#
#
#
# Ex: $(call fetch_patches_from_ml,<package_name>,<package_mls>)
define fetch_patches_from_ml
    echo "Going to $(FETCH_PATCHES) folder"; \
    pushd $(FETCH_PATCHES); \
    if [[ ! -z $2 ]]; then \
        echo "* Collecting patches for $1:"; \
        for token in $2; do \
            if [[ -z $${patch_url} ]]; then \
                patch_url=$${token}; \
                patch_name=; \
                patch_count=; \
                continue; \
            fi; \
            if [[ -z $${patch_name} ]]; then \
                patch_name=$${token}; \
                patch_count=; \
                continue; \
            fi; \
            patch_count=$${token}; \
            wget "$${patch_url}" -O $${patch_name} \
                > $(LOGS)/_$${AT_STEPID}-mailinglist_wget.log.tmp 2>&1; \
            if [[ $${?} -ne 0 ]]; then \
                if grep 'Self-signed certificate encountered.' \
                   $(LOGS)/_$${AT_STEPID}-mailinglist_wget.log.tmp; then \
                    echo "Retrying without certificate check..." \
                         >> $(LOGS)/_$${AT_STEPID}-mailinglist_wget.log.tmp 2>&1; \
                    wget --no-check-certificate "$${patch_url}" \
                         -O $${patch_name} \
                         >> $(LOGS)/_$${AT_STEPID}-mailinglist_wget.log.tmp 2>&1; \
                    if [[ $${?} -ne 0 ]]; then \
                        cat $(LOGS)/_$${AT_STEPID}-mailinglist_wget.log.tmp \
                            >> $(LOGS)/_$${AT_STEPID}-mailinglist_wget.log; \
                        rm -rf $(LOGS)/_$${AT_STEPID}-mailinglist_wget.log.tmp; \
                        echo -e "\tPatch $${patch_name} - [FAILED]"; \
                        rm -rf $${fetch_lock}; \
                        popd; \
                        exit 1; \
                    fi; \
                else \
                    cat $(LOGS)/_$${AT_STEPID}-mailinglist_wget.log.tmp \
                        >> $(LOGS)/_$${AT_STEPID}-mailinglist_wget.log; \
                    rm -rf $(LOGS)/_$${AT_STEPID}-mailinglist_wget.log.tmp; \
                    echo -e "\tPatch $${patch_name} - [FAILED]"; \
                    rm -rf $${fetch_lock}; \
                    popd; \
                    exit 1; \
                fi; \
            fi; \
            cat $(LOGS)/_$${AT_STEPID}-mailinglist_wget.log.tmp \
                >> $(LOGS)/_$${AT_STEPID}-mailinglist_wget.log; \
            rm -rf $(LOGS)/_$${AT_STEPID}-mailinglist_wget.log.tmp; \
            echo -e "\tPatch $${patch_name} - [SUCCESS]"; \
            START=""; \
            count=0; \
            IFS_SAVE=$${IFS}; \
            IFS=; \
            while read -r line; do \
                if [[ -z $${START} ]]; then \
                    START=$$(echo "$${line}" | sed -n '/^diff/p;/^Index/p;/^--- /p'); \
                    if [[ ! -z $${START} ]]; then \
                        count=$$(( count + 1 )); \
                        echo "$${line}" >> $${patch_name}.temp; \
                        continue; \
                    else \
                        continue; \
                    fi; \
                else \
                    count=$$(( count + 1 )); \
                    echo "$${line}" >> $${patch_name}.temp; \
                fi; \
                if [[ $${count} -eq $${patch_count} ]]; then \
                    break; \
                fi; \
            done < $${patch_name}; \
            IFS=$${IFS_SAVE}; \
            mv $${patch_name}.temp $${patch_name}; \
            patch_url=; \
            patch_name=; \
            patch_count=; \
        done; \
    fi; \
    popd
endef


#
#
#
#
# Ex: $(call fetch_sources)
define fetch_sources
    echo "Going to $(FETCH_SOURCES) folder"; \
    pushd $(FETCH_SOURCES); \
    echo "Looking for internal repos on final builds"; \
    num_mirrors=$$(eval echo \$${\#ATSRC_PACKAGE_CO[@]}); \
    internal=$$(eval echo \$${ATSRC_PACKAGE_CO[@]} | grep -o ".ibm.com/" | wc -l); \
    if [[ (( "$(AT_INTERNAL)" == "none" && $${internal} == $${num_mirrors})) ]]; then \
        echo "Internal repositories can only be used by internal builds! Ignoring $1..."; \
    else \
        if [[ -n "$${ATSRC_PACKAGE_PRE}" ]]; then \
            if eval \$${ATSRC_PACKAGE_PRE}; then \
                echo "Component $1 already fetched, skipping it."; \
            else \
                fetch_success='false'; \
                retries=$${ATSRC_PACKAGE_RETRIES:-$(BUILD_DEFAULT_RETRIES)}; \
                num_mirrors=$$(( $$(eval echo \$${#ATSRC_PACKAGE_CO[@]}) - 1 )); \
                echo "Fetching $1 sources:"; \
                while [[ $${retries} -ge 0 ]]; do \
                    echo -en "- Retry cycle: $${retries}.\n"; \
                    for index in $$(seq 0 $${num_mirrors}); do \
                        fetch=$$(eval echo \$${ATSRC_PACKAGE_CO[$${index}]}); \
                        echo -en "\t* Trying mirror: $${fetch}."; \
                        eval $${fetch} > $(LOGS)/_$${AT_STEPID}_fetch_try-$${index}.log 2>&1; \
                        if [[ $${?} -ne 0 ]]; then \
                            echo " - [FAILED]"; \
                        else \
                            echo " - [SUCCESS]"; \
                            fetch_success='true'; \
                            retries=0 && break; \
                        fi; \
                    done; \
                    retries=$$(( retries - 1 )); \
                done; \
                if [[ "$${fetch_success}" == "false" ]]; then \
                    echo "Couldn't get $1 from any of its mirrors!"; \
                    rm -rf $${fetch_lock}; \
                    exit 1; \
                fi; \
                if [[ "$${fetch:0:9}" == "git clone" ]]; then \
                    pushd $1; \
                    echo -en "\t\t- Final git revision checkout $${ATSRC_PACKAGE_REV}\n"; \
                    num_git=$$(( $$(eval echo \$${#ATSRC_PACKAGE_GIT[@]}) - 1 )); \
                    for index in $$(seq 0 $${num_git}); do \
                        fetch=$$(eval echo \$${ATSRC_PACKAGE_GIT[$${index}]}); \
                        echo -en "\t\t* git command: $${fetch}."; \
                        eval $${fetch} > $(LOGS)/_$${AT_STEPID}_git-checkout_$${index}.log 2>&1; \
                        if [[ $${?} -ne 0 ]]; then \
                            rm -rf $${fetch_lock}; \
                            popd; \
                            echo " - [FAIL]"; \
                            exit 1; \
                        else \
                            echo " - [SUCCESS]"; \
                        fi; \
                    done; \
                    popd; \
                fi; \
                echo -en "\t* Preparing final source place of $1"; \
                eval \$${ATSRC_PACKAGE_POST} > $(LOGS)/_$${AT_STEPID}_post.log 2>&1; \
                if [[ $${?} -ne 0 ]]; then \
                    rm -rf $${fetch_lock}; \
                    echo " - [FAIL]"; \
                    exit 1; \
                fi; \
                echo " - [SUCCESS]"; \
                echo -e "\t* Checking for required PORTS option execution"; \
                if [[ "x$${ATSRC_PACKAGE_PORTS}" != "x" ]]; then \
                    pushd $1; \
                    echo -en "\t\t- Existing ports operation execution"; \
                    eval $${ATSRC_PACKAGE_PORTS} > $(LOGS)/_$${AT_STEPID}_ports.log 2>&1; \
                    if [[ $${?} -ne 0 ]]; then \
                        rm -rf $${fetch_lock}; \
                        popd; \
                        echo " - [FAIL]"; \
                        exit 1; \
                    fi; \
                    echo " - [SUCCESS]"; \
                    popd; \
                fi; \
            fi; \
        fi; \
    fi; \
    popd
endef


#
#
#
#
# Ex: $(call fetch_addons,<package_name>,<package_aloc>)
define fetch_addons
    echo "Going to $(FETCH_PATCHES) folder"; \
    pushd $(FETCH_PATCHES); \
    if [[ ! -z $2 ]]; then \
        echo "* Downloading add-ons for $1:"; \
        for addon in $2; do \
            wget -nc "$${addon}" >> \
                 $(LOGS)/_$${AT_STEPID}-addon_wget.log 2>&1; \
            if [[ $${?} -ne 0 ]]; then \
                echo -e "\tAdd-on $${addon} - [FAILED]"; \
                rm -rf $${fetch_lock}; \
                popd; \
                exit 1; \
            fi; \
            echo -e "\tAdd-on $${addon} - [SUCCESS]"; \
        done; \
    fi; \
    popd
endef


#
#
#
#
# Ex: $(call check_packages,<package_list>)
define check_packages
    if [[ -n "$1" ]]; then \
        missing_pkg="no"; \
        tmp_file=$$(mktemp); \
        if [[ ("$(DISTRO_FM)" == "ubuntu") || ("$(DISTRO_FM)" == "debian") ]]; then \
            dpkg -l | tail -n +6 | awk '{ print $$2 "-" $$3; };' > $${tmp_file}; \
        else \
            rpm -qa > $${tmp_file}; \
        fi; \
        echo "*** Begin packages sanity check" > ./sanity.log 2>&1; \
        for chk_pkg in $1; do \
            grep -E "$${chk_pkg}" $${tmp_file} > /dev/null; \
            if [[ $${?} -ne 0 ]]; then \
                echo "Couldn't find $${chk_pkg} required to proceed the build." >> ./sanity.log 2>&1; \
                missing_pkg="yes"; \
            fi; \
        done; \
        echo "*** End packages sanity check" >> ./sanity.log 2>&1; \
        rm -f $${tmp_file}; \
        if [[ "$${missing_pkg}" == "yes" ]]; then \
            echo "abort"; \
        else \
            echo "success"; \
        fi; \
    fi
endef


# Compare two string versions
# Return:
#   0 - version $1 and $2 are equal
#   1 - version $1 is greater than $2
#   2 - version $1 is lesser than $2
# Ex: $(call compare_versions,<version_1>,<version_2>)
define compare_versions
    v1=($$(echo "$1" | tr '.' ' ')); \
    v2=($$(echo "$2" | tr '.' ' ')); \
    if [[ $${#v1[@]} > $${#v2[@]} ]]; then \
        size=$${#v1[@]}; \
    else \
        size=$${#v2[@]}; \
    fi; \
    result=0; \
    for i in $$(seq 0 $$(($${size} - 1))); do \
        if [[ $${v1[$${i}]} -lt $${v2[$${i}]} ]]; then \
            result=2; \
            break; \
        fi; \
        if [[ $${v1[$${i}]} -gt $${v2[$${i}]} ]]; then \
            result=1; \
            break; \
        fi; \
    done; \
    echo $${result}; \
    unset result size v1 v2 i
endef


# Check if executable $1 is installed with version greater or equal to $2
# WARNING: It only works with executables that follow the GNU output format
# for --version
# Ex:
# Return:
#   0 - executable $1 is installed with version greater or equal to $2
#   1 - executable $1 isn't installed
#   2 - executable $1 is installed, but with a version that is less than $2
define check_programs
    if [[ -n "$1" ]]; then \
        missing_pgm="no"; \
        echo "*** Begin programs sanity check" >> ./sanity.log 2>&1; \
        for chk_pgm in $1; do \
            chk_pgm_name=$$(echo $${chk_pgm} | cut -d '_' -f 1 -); \
            chk_pgm_version=$$(echo $${chk_pgm} | \
                               sed "s|$${chk_pgm_name}_\?||"); \
            which $${chk_pgm_name} &> /dev/null; \
            if [[ $${?} -ne 0 ]]; then \
                echo "Couldn't find $${chk_pgm_name} required to proceed the build." >> ./sanity.log 2>&1; \
                missing_pgm="yes"; \
            else \
                if [[ -z "$${chk_pgm_version}" ]]; then \
                    continue; \
                fi; \
                version=$$($${chk_pgm_name} --version | grep $${chk_pgm_name} | awk '{print $$4}'); \
                if [[ -z "$${version}" ]]; then \
                    version=$$($${chk_pgm_name} --version | grep -i $${chk_pgm_name} | awk '{print $$3}'); \
                fi; \
                status=$$($(call compare_versions,$${chk_pgm_version},$${version})); \
                if [[ $${status} -eq 1 ]]; then \
                    echo "The $${chk_pgm_name} program version $${version} isn't up to date... We need at least version $${chk_pgm_version}." >> ./sanity.log 2>&1; \
                    missing_pgm="yes"; \
                fi; \
            fi; \
        done; \
        echo "*** End programs sanity check" >> ./sanity.log 2>&1; \
        if [[ "$${missing_pgm}" == "yes" ]]; then \
            echo "abort"; \
        else \
            echo "success"; \
        fi; \
    fi; \
    unset missing_pgm chk_pgm chk_pgm_name chk_pgm_version version status
endef


#
#
#
#
# Ex: $(call build_release_notes,<package_list>)
define build_release_notes
    set -e; \
    RELNOTES_DIR=$(CONFIG)/release_notes; \
    rm -rf $(TEMP_INSTALL)/release_notes-group_*.html; \
    rm -rf $(TEMP_INSTALL)/release_notes-groups.html; \
    rm -rf $(TEMP_INSTALL)/release_notes-inst.html; \
    rm -rf $(TEMP_INSTALL)/release_notes-final.html; \
    for PKG in $1; do \
        AT_KERNEL=$(AT_KERNEL); \
        source $(CONFIG)/packages/$${PKG}/sources; \
        if [[ "$${ATSRC_PACKAGE_EXCLUDE_RN}" == "yes" ]]; then \
            unset $${!ATSRC_PACKAGE_*}; \
            continue; \
        fi; \
        if [[ "$${ATSRC_PACKAGE_BUNDLE}" != "$${GROUP}" ]]; then \
            GROUP=$${ATSRC_PACKAGE_BUNDLE}; \
            [[ -z "$${GROUPLIST}" ]] && GROUPLIST=$${GROUP} || GROUPLIST="$${GROUPLIST} $${GROUP}"; \
        fi; \
        [[ -n "$${ATSRC_PACKAGE_NAMESUFFIX}" ]] && ATSRC_PACKAGE_NAMESUFFIX=" $${ATSRC_PACKAGE_NAMESUFFIX}"; \
        if [[ -n "$${ATSRC_PACKAGE_DOCLINK}" ]]; then \
            DOCLINK=" $$(cat $${RELNOTES_DIR}/release_notes-online_doc.html | \
                             sed "s@__PACKAGE_DOCLINK__@$${ATSRC_PACKAGE_DOCLINK//&/\&}@g" | tr '\n' ' ')"; \
        else \
            unset DOCLINK; \
        fi; \
        cat $${RELNOTES_DIR}/release_notes-package_line.html | \
            sed "s@__PACKAGE_NAME__@$${ATSRC_PACKAGE_NAME}@g" | \
            sed "s@__PACKAGE_VERSION__@$${ATSRC_PACKAGE_VER}@g" | \
            sed "s@__PACKAGE_REVISION__@$${ATSRC_PACKAGE_REV:+-$${ATSRC_PACKAGE_REV}}@g" | \
            sed "s@__PACKAGE_NAME_SUFFIX__@$${ATSRC_PACKAGE_NAMESUFFIX}@g" | \
            sed "s@__ONLINE_DOCS__@$${DOCLINK}@g" >> $(TEMP_INSTALL)/release_notes-group_$${GROUP}.html; \
        echo "<ul>" >> $(TEMP_INSTALL)/release_notes-group_$${GROUP}.html; \
        subpackage=0; \
        subpackage_name="ATSRC_PACKAGE_SUBPACKAGE_NAME"_$${subpackage}; \
        subpackage_name=`echo $${!subpackage_name}`; \
        while [[ -n $${subpackage_name} ]] ; do \
            subpackage_link="ATSRC_PACKAGE_SUBPACKAGE_DOCLINK"_$${subpackage}; \
            subpackage_link=`echo $${!subpackage_link}`; \
            if [[ -n "$${subpackage_link}" ]]; then \
                DOCLINK=" $$(cat $${RELNOTES_DIR}/release_notes-online_doc.html | \
                                 sed "s@__PACKAGE_DOCLINK__@$${subpackage_link//&/\&}@g" | tr '\n' ' ')"; \
            else \
                unset DOCLINK; \
            fi; \
            cat $${RELNOTES_DIR}/release_notes-package_line.html | \
                sed "s@__PACKAGE_NAME__@$${subpackage_name}@g" | \
                sed "s@__PACKAGE_VERSION__@$${ATSRC_PACKAGE_VER}@g" | \
                sed "s@__PACKAGE_REVISION__@$${ATSRC_PACKAGE_REV:+-$${ATSRC_PACKAGE_REV}}@g" | \
                sed "s@__PACKAGE_NAME_SUFFIX__@@g" | \
                sed "s@__ONLINE_DOCS__@$${DOCLINK}@g" >> $(TEMP_INSTALL)/release_notes-group_$${GROUP}.html; \
            subpackage=$$(($$subpackage + 1)); \
            subpackage_name="ATSRC_PACKAGE_SUBPACKAGE_NAME"_$${subpackage}; \
            subpackage_name=`echo $${!subpackage_name}`; \
        done; \
        echo "</ul>" >> $(TEMP_INSTALL)/release_notes-group_$${GROUP}.html; \
        unset $${!ATSRC_PACKAGE_*}; \
    done; \
    while read GROUP_LINE; do \
        if grep -e '^#\* ' <(echo $${GROUP_LINE}) > /dev/null 2>&1; then \
            GROUP="$$(echo $${GROUP_LINE/\#\* /} | cut -d ':' -f 1)"; \
            GROUP="$${GROUP#"$${GROUP%%[![:space:]]*}"}"; \
            GROUP="$${GROUP%"$${GROUP##*[![:space:]]}"}"; \
            GROUP_DESC="$$(echo $${GROUP_LINE/\#\* /} | cut -d ':' -f 2)"; \
            GROUP_DESC="$${GROUP_DESC#"$${GROUP_DESC%%[![:space:]]*}"}"; \
            GROUP_DESC="$${GROUP_DESC%"$${GROUP_DESC##*[![:space:]]}"}"; \
            if [[ -r $(TEMP_INSTALL)/release_notes-group_$${GROUP}.html ]]; then \
                cat $${RELNOTES_DIR}/release_notes-group_entry.html | \
                    sed "s/__GROUP_DEFINITION__/$${GROUP_DESC}/g" | \
                    sed "/__PACKAGE_LINES__/r $(TEMP_INSTALL)/release_notes-group_$${GROUP}.html" | \
                    sed "/__PACKAGE_LINES__/d" >> $(TEMP_INSTALL)/release_notes-groups.html; \
            fi; \
        fi; \
    done < "$(CONFIG)/packages/groups"; \
    if [[ -r $(TEMP_INSTALL)/release_notes-groups.html ]]; then \
        cat $${RELNOTES_DIR}/release_notes-features.html | \
            sed "/__GROUPS_ENTRIES__/r $(TEMP_INSTALL)/release_notes-groups.html" | \
            sed "/__GROUPS_ENTRIES__/d" | \
            sed "/__AT_FEATURES__/r $${RELNOTES_DIR}/relfixes.html" | \
            sed "/__AT_FEATURES__/d" > $(TEMP_INSTALL)/release_notes-features.html; \
    else \
        echo "No package groups found to build release notes... Giving up on this!"; \
        exit 1; \
    fi; \
    sed "/if_$(DISTRO_AB)/d" "$${RELNOTES_DIR}/release_notes-inst.html" > \
        $(TEMP_INSTALL)/release_notes-inst.html; \
    cat $${RELNOTES_DIR}/release_notes-body.html | \
        sed "/__INCLUDED_STYLE__/r $${RELNOTES_DIR}/release_notes-style.html" | \
        sed "/__INCLUDED_STYLE__/d" | \
        sed "/__FEATURES__/r $(TEMP_INSTALL)/release_notes-features.html" | \
        sed "/__FEATURES__/d" | \
        sed "/__INST__/r $(TEMP_INSTALL)/release_notes-inst.html" | \
        sed "/__INST__/d" > $(TEMP_INSTALL)/release_notes-final.html; \
    if [[ "$(AT_INTERNAL)" == "none" ]]; then \
        VERSION=$(AT_MAJOR); \
    else \
        VERSION=$(AT_MAJOR)-$(AT_INTERNAL); \
    fi; \
    OLD_VERSION=$$(echo "$(AT_MAJOR_VERSION) - 1" | bc); \
    cat $(TEMP_INSTALL)/release_notes-final.html | \
        sed "s@__SUPPORTED_CPUS__@$$(echo "$(sort $(TUNED_PROCESSORS) $(BUILD_OPTIMIZATION))" | tr " " ",")@g" | \
        sed "s@__VERSION__@$${VERSION}@g" | \
        sed "s@__OLD_VERSION__@$${OLD_VERSION}@g" | \
        sed "s@__VERSION_RELEASE__@$(AT_VER_REV)@g" | \
        xmllint --html --format - > $(RELNOT_FILE); \
    set +e; \
    unset VERSION OLD_VERSION GROUP GROUPLIST DOCLINK RELNOTES_DIR
endef
