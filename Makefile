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
# Advance Toolchain main Makefile
#
# This file is where all the build starts.
#
# Common targets:
#	all - Default target.  Build and package the Advance Toolchain.
#		Options:
#			DESTDIR - Specify the directory where the AT directory
#				will be created, e.g.: DESTDIR=/opt
#
#			AT_CONFIGSET - Indicates which config set to use.
#				Possible values include the name of directories
#				inside configs/, e.g.: AT_CONFIGSET=7.0
#
#			BUILD_DEBUG_ON - Forces that all build stages be
#				retained.  Possible values are "yes" or "no".
#				If set to "yes", all temporary build steps are
#				retained, regardless of the package setting on
#				ATCFG_HOLD_* variables.
#
#			BUILD_ARCH - Specify which archicteture this toolchain
#				will be targeting.  Most config sets have their
#				default values, but in same cases the config
#				set is able to build toolchains for different
#				architectures, e.g.: BUILD_ARCH=ppc64le or
#				BUILD_ARCH=ppc64
#
#			AT_MAKE_CHECK - Specify if package testing should be
#				done during the build.  Setting this to a value
#				other than 'none' will enable testing for all
#				packages that have atcfg_make_check defined in
#				their stage file.  This can be overridden at
#				the package level by setting the value of
#				ATSRC_PACKAGE_MAKE_CHECK in a package's
#				source file.  The values for this variable are:
#				- none:  do not enable package testing at the
#				global level
#				- strict_fail:  Enable package testing at the
#				global level and cause the build to fail if
#				a package's testing fails.
#				- silent_fail:  Enable package testing at the
#				global level but do not cause the build to
#				fail if the package's testing fails.
#
#			BUILD_IGNORE_COMPAT - Tells to ignore runtime-compat
#				package building. If not provided, it's inferred
#				by the contents of AT_OLD_KERNEL on the specific
#				<distro>.mk config file.
#
#			BUILD_IGNORE_AT_COMPAT - Tells to ignore atXX-compat
#					package building. If not provided, it's inferred
#					by the contents of other configset variables.
#
#	pack - Create a tarball with all the source code necessary to build AT
#		on another server.
#
#	clone - Clone a config set, copying or symlinking its files.
#		Options:
#			FROM - Name of the config set being cloned.
#
#			TO - Name of config set being create.
#
#
#	test / fvtr - Runs the build and the FVTR test suite to validate it.
#		Options:
#			TEST_NAME - Name of a particular test suite case to
#				run (this limits the test case run to this
#				single test).
#

# Make sure we're running a recent enough GNU make version.'
ifneq (3.81,$(firstword $(sort $(MAKE_VERSION) 3.81)))
    $(error "This file requires GNU make 3.81 or newer version.")
endif

# Set the proper shell to use
SHELL := /bin/bash
# Some shells don't load all the standard values (Ubuntu), so we have to
# manually set all those we need.
USER  ?= $(shell whoami)

# Set some basic path information
AT_BASE ?= $(shell pwd)
CONFIG_ROOT := $(AT_BASE)/configs
SCRIPTS_ROOT := $(AT_BASE)/scripts
SCRIPTS_REPO := $(SCRIPTS_ROOT)/repository
HELPERS_ROOT := $(SCRIPTS_ROOT)/helpers
RPMSPEC_ROOT := $(SCRIPTS_ROOT)/specs
SKELETONS_ROOT := $(SCRIPTS_ROOT)/skeletons
UTILITIES_ROOT := $(SCRIPTS_ROOT)/utilities
FETCH_SOURCES := $(AT_BASE)/sources
FETCH_PATCHES := $(AT_BASE)/patches

# Define the build timestamp
AT_TODAY := $(shell date "+%Y%m%d")

# Define the format of the running timestamp
TIME := date -u +%Y-%m-%d_%H.%M.%S

# Only set build environment for targets other the 'clone', 'edit' and 'pack'
ifeq (,$(findstring $(MAKECMDGOALS),clone edit pack))

    # Begin setting build environment                     *****
    # *********************************************************

    # Find the host arch where the AT is being build
    HOST_ARCH := $(shell uname -m 2>&1)

    # Check for the required config parameter (config path)
    ifndef AT_CONFIGSET
        AT_CONFIGSET := $(shell ls -d $(CONFIG_ROOT)/[0-9]*.[0-9] | awk -F '/' '{ print $$NF }' | sort -n | tail -1)
        ifeq ($(AT_CONFIGSET),)
            $(error Couldn't infer AT_CONFIGSET variable, and no hint was given... Bailing out!)
        else
            $(warning AT_CONFIGSET variable not informed... Using latest one ($(AT_CONFIGSET)).)
        endif
    endif

    # Verify the setting of AT_MAKE_CHECK

    AT_MAKE_CHECK ?= none
    ifeq (,$(findstring $(AT_MAKE_CHECK),none strict_fail silent_fail))
        $(warning unrecognized value for AT_MAKE_CHECK... value none assumed.)
        AT_MAKE_CHECK := none
    endif

    CONFIG := $(CONFIG_ROOT)/$(AT_CONFIGSET)
    CONFIG_SPEC := $(CONFIG)/specs
    DEBH_ROOT   := $(CONFIG)/deb

    # Load all config directives for the build
    include $(CONFIG)/base.mk
    include $(CONFIG)/build.mk
    include $(CONFIG)/sanity.mk

    # Define a simple check for file validation
    # $(call file_exists,<filename>)
    define file_exists
        if [[ -r $1 ]]; then \
            echo "found"; \
        else \
            echo "none"; \
        fi
    endef

    # Define a verification for progname
    # $(call find_prg,<progname>)
    define find_prg
        for DIR in $$(echo $${PATH} | tr ":" "\t"); do \
            if [[ -x "$${DIR}/$1" ]]; then \
                echo "$${DIR}/$1"; \
                break; \
            fi; \
        done
    endef

    # Assign some essential tools for the build to defines and verify its existence
    # lsb_release
    LSBTOOL := $(strip $(shell $(call find_prg,lsb_release)))
    ifeq ($(LSBTOOL),)
        LSBTOOL := $(UTILITIES_ROOT)/lsb_release
    endif
    # ld
    GCC_LD := $(strip $(shell $(call find_prg,ld)))
    ifeq ($(GCC_LD),)
        $(error Program linker not found... Bailing out!)
    endif
    # as
    GCC_AS := $(strip $(shell $(call find_prg,as)))
    ifeq ($(GCC_AS),)
        $(error Basic assembler not found... Bailing out!)
    endif
    # gcc
    SYSTEM_CC := $(strip $(shell $(call find_prg,gcc)))
    ifeq ($(SYSTEM_CC),)
        $(error No gcc system toolchain installed... Bailing out!)
    endif
    # g++
    SYSTEM_CXX := $(strip $(shell $(call find_prg,g++)))
    ifeq ($(SYSTEM_CXX),)
        $(error No g++ system toolchain installed... Bailing out!)
    endif
    # autoconf
    AUTOCONF := $(strip $(shell $(call find_prg,autoconf)))
    ifeq ($(AUTOCONF),)
        $(error No autoconf installed... Bailing out!)
    endif

    # Load basic utilities
    ifeq ($(strip $(shell $(call file_exists,$(HELPERS_ROOT)/utilities.mk))),found)
        include $(HELPERS_ROOT)/utilities.mk
    else
        $(error Couldn't find the utilities helper macro... Bailing out!)
    endif

    # Collect the distro version in which it's being run
    DISTRO_INFO := $(shell $(call get_distro_info))
    DISTRO_ID := $(shell echo $(DISTRO_INFO) | cut -d ' ' -f 1)
    DISTRO_AB := $(shell echo $(DISTRO_INFO) | cut -d ' ' -f 2)
    DISTRO_FM := $(shell echo $(DISTRO_ID) | cut -d '-' -f 1)
    DISTRO_FILE := $(CONFIG)/distros/$(DISTRO_ID).mk
    export DISTRO_ID

    # Check if the running distro is supported for builds
    ifeq ($(strip $(shell $(call file_exists,$(DISTRO_FILE)))),found)
        include $(DISTRO_FILE)
    else
        $(error Distro $(DISTRO_ID) not supported... Bailing out!)
    endif

    # When doing a cross build, if the executables should be 32 bit
    # reset the HOST_ARCH from x86_64 to i686.
    ifeq ($(HOST_ARCH),x86_64)
        ifeq ($(BUILD_CROSS_32),yes)
            HOST_ARCH := i686
        endif
    endif

    # Prepare the SUB_MAKE variable to use in recipes sub make calls
    export SUB_MAKE = $(MAKE)

    # Set more path information
    BUILD_ID := $(DISTRO_ID)_$(HOST_ARCH)_$(BUILD_ARCH)

    # First things first... Check for general build sanity before proceeding
    BASE_SANITY := $(strip $(shell $(call base_sanity)))

    # Define some internal version name variables
    AT_VER_REV := $(AT_MAJOR_VERSION)-$(AT_REVISION_NUMBER)
    AT_MAJOR := $(AT_NAME)$(AT_MAJOR_VERSION)
    ifeq ($(AT_INTERNAL),none)
        AT_FULL_VER := $(AT_VER_REV)
    else
        AT_FULL_VER := $(AT_VER_REV)-$(AT_INTERNAL)
    endif
    AT_VER_REV_INTERNAL := $(AT_NAME)$(AT_FULL_VER)

    # Macro to check the terminal in which we are being executed
    define check_terminal
        if [[ ! (("$${TERM:0:6}" == "screen" || $${#TMUX} -gt 0)) ]]; then \
            echo "no_session"; \
        else \
            echo "session"; \
        fi
    endef

    # Check which kind of terminal are we running on...
    TERMINAL := $(shell $(call check_terminal))
    # If its not a session safe terminal kind, issue a warning...
    ifeq ($(TERMINAL),no_session)
        $(warning **************************************************)
        $(warning You are running this build from a bare shell...)
        $(warning Please consider using screen or tmux for this.)
        $(warning **************************************************)
    endif

    # Macro to get all packages name's
    define get_package_list
        for package in $$(find $(CONFIG)/packages/* -type d -print); do \
            [[ -r $${package}/sources ]] && \
                echo $$(basename $${package}); \
        done
    endef

    # Macro to get all packages built.
    # Extract the list from $(build_targets) variable.
    define get_built_packages
        $(sort $(foreach name,$(basename $(notdir $(build_targets))),\
            $(shell echo $(name) | cut -d_ -f1)))
    endef

    # Export settings for the FVTR
    # $(call build_fvtr_conf,<package_list>)
    define build_fvtr_conf
        AT_KERNEL=$(AT_KERNEL); \
        utilities=$(UTILITIES_ROOT); \
        echo "AT_NAME=\"${AT_NAME}\"" > $(CONFIG_EXPT); \
        echo "AT_MAJOR_VERSION=\"${AT_MAJOR_VERSION}\"" >> $(CONFIG_EXPT); \
        echo "AT_REVISION_NUMBER=\"${AT_REVISION_NUMBER}\"" >> $(CONFIG_EXPT); \
        echo "AT_INTERNAL=\"${AT_INTERNAL}\"" >> $(CONFIG_EXPT); \
        echo "AT_DEST=\"${AT_DEST}\"" >> $(CONFIG_EXPT); \
        echo "AT_BUILD_ARCH=\"${BUILD_ARCH}\"" >> $(CONFIG_EXPT); \
        echo "AT_CROSS_BUILD=\"${CROSS_BUILD}\"" >> $(CONFIG_EXPT); \
        echo "AT_TARGET=\"${TARGET}\"" >> $(CONFIG_EXPT); \
        echo "AT_HOST_ARCH=\"${HOST_ARCH}\"" >> $(CONFIG_EXPT); \
        echo "AT_BUILD_LOAD_ARCH=\"${BUILD_LOAD_ARCH}\"" >> $(CONFIG_EXPT); \
        echo "AT_OPTMD_LIBS=\"${BUILD_ACTIVE_MULTILIBS}\"" >> $(CONFIG_EXPT); \
        for PKG in $1; do \
            source $(CONFIG)/packages/$${PKG}/sources; \
            PKG_NAME=$$(echo "$${PKG}" | awk '{print toupper($$0)}'); \
            echo "AT_$${PKG_NAME}_VER=$${ATSRC_PACKAGE_VER}" >> $(CONFIG_EXPT); \
        done; \
        echo created
    endef

    # Pack the assigned source packages to include them into the distribution
    # tarball
    # $(call pack_source_pkgs,<package_list>)
    define pack_source_pkgs
        set -e; \
        AT_KERNEL=$(AT_KERNEL); \
        utilities=$(UTILITIES_ROOT); \
        rm -f $(SRC_TAR_FILE); \
        for PKG in $1; do \
            source $(CONFIG)/packages/$${PKG}/sources; \
            if [[ "$${ATSRC_PACKAGE_DISTRIB}" == "yes" ]]; then \
                tar_pkgs="$${tar_pkgs} $$(basename $${ATSRC_PACKAGE_WORK})"; \
            fi; \
            unset $${!ATSRC_PACKAGE_*}; \
        done; \
        tar_pkgst=$$(echo $${tar_pkgs#$${tar_pkgs%%[![:space:]]*}}); \
        tar cpzf $(SRC_TAR_FILE) -C $(SOURCE) $${tar_pkgst}; \
        set +e
    endef

    # Define a logging macro for a given command
    # $(call runandlog,<logfile>,<command>)
    define runandlog
        { echo "Logging the following command at:"; \
          date; \
          echo; \
          set -x; \
          $2; \
          ret=$${?}; \
          set +x; \
          echo; \
          date; \
          echo "-----------------------------------------------------"; \
        } &>> $1
    endef

    # Create path if needed and return its name
    # $(call mkpath,<pathname>,<force_clean>)
    define mkpath
        if [[ -n "$1" ]]; then \
            fpath=$$(echo $1 | sed 's|//*|/|g'); \
            if [[ -r $${fpath} ]]; then \
                if [[ "$2" == "yes" ]]; then \
                    rm -rf $${fpath}/*; \
                fi; \
            elif [[ -e $${fpath} ]]; then \
                echo "You can't access this path: $${fpath}. Aborting."; \
                exit 1; \
            else \
                mkdir -p $${fpath}; \
            fi; \
            echo $${fpath}; \
            unset fpath; \
        else \
            echo $1; \
        fi
    endef

    # Find the number of SMT cores available
    # $(call get_smt_cores)
    define get_smt_cores
        if [[ -r /proc/cpuinfo ]]; then \
            CPU_TYPE=$$(cat /proc/cpuinfo | grep cpu | cut -f 2 -d ':' | sort -u | sed 's@^ @@' | cut -f 1 -d ' '); \
            CORES_FOUND=$$(cat /proc/cpuinfo | grep "processor" | wc -l); \
            echo $${CORES_FOUND}; \
        else \
            echo 0; \
        fi
    endef

    # Sanity checks for ld and gcc
    # $(call sanity_gcc)
    define sanity_gcc
        if [[ $$(gcc -v --help 2>&1 | grep secure-plt | wc -l) -eq 0 ]]; then \
            echo "Failure. Host GCC is too old."; \
            exit 1; \
        fi
    endef
    # $(call sanity_ld)
    define sanity_ld
        if [[ $$($(GCC_LD) --help 2>&1 | grep bss-plt | wc -l) -eq 0 ]]; then \
            echo "Failure. Host $(GCC_LD) is too old."; \
            exit 1; \
        fi
    endef

    # Create a script to call make again with the same arguments
    # $(call create_remake)
    define create_remake
        echo "#/bin/bash" > remake.sh; \
        echo -n "make DESTDIR='$(DESTDIR)'" >> remake.sh; \
        echo -n " AT_CONFIGSET='$(AT_CONFIGSET)'" >> remake.sh; \
        echo -n " BUILD_ARCH='$(BUILD_ARCH)'" >> remake.sh; \
        echo -n " AT_DIR_NAME='$(AT_DIR_NAME)' \"\$${@}\"" >> remake.sh; \
        chmod +x remake.sh; \
        echo created
    endef

    # Set the required variables for optimized libraries targets.
    #
    # Parameters:
    # 1. <component name>: Name of the component being built, e.g.: glibc
    #
    # Description:
    # This macro filters the conditions to call provide_proc_tuned macro and
    # clears the $(<component>_tuned-archdeps) variable.
    # In the end the following variables will be properly configured:
    # - tuned_targets
    # - <component>_tuned-archdeps
    # - <component>_<processor>-deps      - only if necessary
    # - <component>_<processor>-32-deps   - only if necessary
    # - <component>_<processor>-64-deps   - only if necessary
    #
    # Example:
    # $(call provide_tuneds,<component>)
    define provide_tuneds
        # Hack around an issue where foreach iterates over a null variable
        ifneq ($(TUNED_PROCESSORS),)
            # List this package as a dependency in the global tuned target
            tuned-targets += $(RCPTS)/$(1)_tuned.rcpt
            $(foreach proc,$(TUNED_PROCESSORS),\
               $(eval $(call provide_proc_tuned,$(1),$(proc))))
            $(1)_tuned-archdeps += $($(1)_tuned-32-archdeps) \
                                   $($(1)_tuned-64-archdeps)
        endif
    endef

    # Setup the variables of a optimized library according to the processor
    # and depending on cross compiler settings.
    #
    # Parameters:
    # 1. <component name>: Name of the component being built, e.g.: glibc
    # 2. <processor>: Name of the processor to which this component is going to be
    #                 optimized to, e.g.: power7
    define provide_proc_tuned
        ifeq (x$(CROSS_BUILD),xyes)
            ifeq (x$(BUILD_TUNED_ON_CROSS),xyes)
                $(call set_provides_arch_tuned,$(1),$(2))
            endif
        else
            $(call set_provides_arch_tuned,$(1),$(2))
        endif
    endef

    # Define the required variables of optimized libraries according to its target.
    #
    # Parameters:
    # 1. <component name>: Name of the component being built, e.g.: glibc
    # 2. <processor>: Name of the processor to which this component is going to be
    #                 optimized to, e.g.: power7
    # Check if this target doesn't require bi-arch tuned libs.
    define set_provides_arch_tuned
        ifdef $(1)_tuned-deps
            $(1)_tuned-archdeps += $(RCPTS)/$(1)_$(2).tuned.b.rcpt
            $(1)_$(2)-deps := $($(1)_tuned-deps)
        else
            ifdef BUILD_TARGET_ARCH32
                $(1)_tuned-32-archdeps += $(RCPTS)/$(1)_$(2)-32.tuned.b.rcpt
                $(1)_$(2)-32-deps := $($(1)_tuned-32-deps)
            endif
            ifdef BUILD_TARGET_ARCH64
                $(1)_tuned-64-archdeps += $(RCPTS)/$(1)_$(2)-64.tuned.b.rcpt
                $(1)_$(2)-64-deps := $($(1)_tuned-64-deps)
            endif
        endif
    endef

    # This macro filters and prepares the requirements for the given target_name
    #
    # Parameters:
    # 1. <target_name>: This is the target name to base your requirements.
    # 2. <kind_of_requires>: This is the kind of requires to define (multi =
    #                        32/64 deps, single = no 32/64 deps).
    # 3. <cross_build>: This informs the inclusion of this dependency for cross
    #                   builds (cross_yes = build on cross, cross_no = don't
    #                   build on cross).
    # 4. <skip_arch>:   (Optional) This informs to skip this dependency for
    #                   builds on given arch (skip_ppc64 = skip on ppc64 build,
    #                   skip_ppc64le = skipe on ppc64le build).
    #
    # Description:
    # This macro filters the conditions to call the set_provides_arch macro and
    # clears the $(<target_name>-archdeps) variable.
    #
    # Example:
    # $(call set_provides,<target_name>,<kind_of_requires>,<cross_build>[,<skip_arch>])
    define set_provides
        $(1)-archdeps :=
        ifneq ($(CROSS_BUILD),yes)
            ifneq ($(4),skip_$(BUILD_ARCH))
                $(call set_provides_arch,$(1),$(2))
            endif
        else
            ifeq ($(3),cross_yes)
                $(call set_provides_arch,$(1),$(2))
            endif
        endif
    endef

    # This macro prepares the requirements for the given target_name
    #
    # Parameters:
    # 1. <target_name>: This is the target name to base your requirements.
    # 2. <kind_of_requires>: This is the kind of requires to define (multi =
    #                        32/64 deps, single = no 32/64 deps).
    #
    # Description:
    # This macro defines the variables $(<target_name>-archdeps) that should be
    # used to set the dependencies of the master target <target-name>. It also
    # includes the target as a dependency to "all" through the variable
    # $(build_targets)
    #
    # Example:
    # $(call set_provides_arch,<target_name>,<kind_of_requires>,<cross_build>)
    define set_provides_arch
        ifeq ($(2),multi)
            ifdef BUILD_TARGET_ARCH32
                $(1)-archdeps += $(RCPTS)/$(1)-32.b.rcpt
            endif
            ifdef BUILD_TARGET_ARCH64
                $(1)-archdeps += $(RCPTS)/$(1)-64.b.rcpt
            endif
        else
            $(1)-archdeps := $(RCPTS)/$(1).b.rcpt
        endif
        build_targets += $(RCPTS)/$(1).rcpt
    endef

    define collect_logs
        @fname=collected_logs-$(AT_VER_REV_INTERNAL).$(BUILD_ID)_$$($(TIME)).tar.gz; \
        echo -e "$$($(TIME)) Collecting log information to $${fname}... "; \
        { unset commit_info; \
            if [[ -f commit.info ]]; then \
                cp -p commit.info $(AT_WD); \
                commit_info="./commit.info"; \
            fi; \
            cd $(AT_WD) && \
            tar czf collected_logs.tar.gz \
                ./logs/* ./dynamic $${commit_info} \
                $$(find ./builds -name 'config.[hlms]*' -print); \
            mv -f $(AT_WD)/collected_logs.tar.gz $(AT_BASE)/$${fname}; \
            unset commit_info; \
        } > /dev/null 2>&1; \
        echo "$$($(TIME)) Log information collected!"
    endef

    # This is a simple heuristics to find out if we need to build the atXX-compat
    # RPM package. It's loose and wide in tending to choose a build instead of a
    # build denial (it considers "compat" and "supported" previous AT distros), so
    # if you are sure that you must skip this package build, state it clearly on
    # the config files (preferably on the distro.mk related file), or the check
    # could be further restrained.
    # Having said that, there is a quick description of its logic:
    # We first collect all the supported and compat distros related to this build,
    # and for each of them, (from earliest to oldest) we try to locate base support
    # for it on the previous AT version. If base support is found, we try to
    # identify if the particular build being done was supported (BE or LE). If it's
    # found, we send back a "no" as a GO for the build of atXX-compat, otherwise,
    # we send back a "yes" as a NO GO (ignore) for the build of atXX-compat.
    # Note that we could restrain it further, looking only for AT previous
    # "supported" distros, but I'm not sure that it's the correct path to follow.
    define build_at_compat_rpm
        compat_distros=$$(echo $(AT_COMPAT_DISTROS) \
                               $(AT_SUPPORTED_DISTROS) | \
                          sed 's|RHEL|redhat-|g' | \
                          sed 's|SLES_|suse-|g' | \
                          tr ' ' '\n' | sort -ru | tr '\n' ' '); \
        if [[ -n "$${compat_distros}" ]]; then \
            for distro in $${compat_distros}; do \
                distro_file="$(CONFIG_ROOT)/$(AT_PREVIOUS_VERSION)/distros/$${distro}.mk"; \
                if [[ -f $${distro_file} ]]; then \
                    supp_archs="$$(cat $${distro_file} | \
                                   grep -o '^AT_SUPPORTED_ARCHS.*$$' | \
                                   sed 's|AT_SUPPORTED_ARCHS := ||g') "; \
                    if [[ "$${supp_archs}" != "$${supp_archs/$(BUILD_ARCH) /}" ]]; then \
                        at_comp_found="true"; \
                        break; \
                    fi; \
                fi; \
            done; \
            if [[ "$${at_comp_found}" == "true" ]]; then \
                echo "no"; \
            else \
                echo "yes"; \
            fi; \
        else \
            echo "yes"; \
        fi
    endef

    # Copy files from $(1) to $(2) if it exists.
    #
    # Parameters:
    # 1. <source file>: Name of the file to be copied.
    # 2. <destination>: Destination where the source file will be saved.
    define copy_if_exists
        if [[ -n "$(1)" && -e "$(1)" ]]; then \
            echo "- $$(basename $(1))"; \
            cp $(1) $(2); \
        fi
    endef

    # Create a path, if it fails try to use super-user permission.
    # $(call sudo_mkdir, <pathname>)
    define sudo_mkdir
        if [[ ! (-r $1) ]]; then \
            mkdir -p $1; \
            if [[ ! (-r $1) ]]; then \
                echo "Cannot create $1, trying as super-user..."; \
                sudo mkdir -p $(1) && sudo chown "$${USER}." $(1); \
            fi; \
        fi
    endef

    # Define the installation path
    # DESTDIR, is optional and should be externally defined.
    DESTDIR ?= /opt
    # Canonicalize DESTDIR path
    DESTDIR := $(shell readlink -m "${DESTDIR}")

    ifneq ($(AT_INTERNAL),none)
        AT_MAJOR_INTERNAL := $(AT_MAJOR)-$(AT_INTERNAL)
        AT_DIR_NAME ?= $(AT_VER_REV_INTERNAL)
    else
        AT_MAJOR_INTERNAL := $(AT_MAJOR)
        AT_DIR_NAME ?= $(AT_MAJOR)
    endif

    AT_DEST := $(shell echo $(DESTDIR)/$(AT_DIR_NAME) | sed 's|//*|/|g')
    MESSAGE := $(shell $(call sudo_mkdir,$(AT_DEST)))
    ifneq ($(MESSAGE),)
        $(warning $(MESSAGE))
    endif
    ifeq ($(strip $(shell $(call file_exists,$(AT_DEST)))),none)
        $(error Couldn't create directory $(AT_DEST)... Bailing out!)
    endif

    # If the user wants to use a prespecified AT_BUILD we don't care. Otherwise we
    # use the current working directory.
    AT_WD ?= $(AT_BASE)/$(AT_VER_REV_INTERNAL).$(BUILD_ID)

    # Define the actual TEMP_INSTALL path to use on build
    TEMP_INSTALL := $(AT_BASE)/tmp.$(AT_VER_REV_INTERNAL).$(BUILD_ID)

    # Prepare the list of all packages
    PACKAGES_LIST := $(strip $(shell $(call get_package_list)))

    # Prepare the tuned processors and libs list
    TUNED_PROCESSORS := $(sort $(BUILD_ACTIVE_MULTILIBS))

    # Define and create the build structure folders
    LOGS := $(strip $(shell $(call mkpath,$(AT_WD)/logs,no)))
    RPMS := $(strip $(shell $(call mkpath,$(AT_WD)/rpms,no)))
    DEBS := $(strip $(shell $(call mkpath,$(AT_WD)/debs,no)))
    PACKS := $(strip $(shell $(call mkpath,$(AT_WD)/tarball,no)))
    RCPTS := $(strip $(shell $(call mkpath,$(AT_WD)/receipts,no)))
    BUILD := $(strip $(shell $(call mkpath,$(AT_WD)/builds,no)))
    SOURCE := $(strip $(shell $(call mkpath,$(AT_WD)/sources,no)))
    DYNAMIC_ROOT := $(strip $(shell $(call mkpath,$(AT_WD)/dynamic,no)))
    DYNAMIC_SPEC := $(strip $(shell $(call mkpath,$(DYNAMIC_ROOT)/spec,no)))
    DYNAMIC_LOAD := $(strip $(shell $(call mkpath,$(DYNAMIC_ROOT)/load,no)))
    TEMP_INSTALL := $(strip $(shell $(call mkpath,$(TEMP_INSTALL),no)))
    ifeq ($(AT_USE_FEDORA_RELNAM),yes)
        RELNOT_FILE  := $(RPMS)/release_notes.$(AT_NAME)-$(AT_FULL_VER).tmp
        SRC_TAR_FILE := $(PACKS)/$(AT_NAME)-src-$(AT_FULL_VER).tgz
    else
        RELNOT_FILE  := $(RPMS)/release_notes.$(AT_MAJOR_INTERNAL)-$(AT_VER_REV).tmp
        SRC_TAR_FILE := $(PACKS)/advance-toolchain-$(AT_MAJOR_INTERNAL)-src-$(AT_VER_REV).tgz
    endif
    # Name of the exported config file.
    CONFIG_EXPT := $(DYNAMIC_ROOT)/config_$(AT_VER_REV_INTERNAL).$(BUILD_ID)
    # Define some fetch folder structure
    FETCH_SOURCES := $(strip $(shell $(call mkpath,$(FETCH_SOURCES),no)))
    FETCH_PATCHES := $(strip $(shell $(call mkpath,$(FETCH_PATCHES),no)))

    # If everything is fine until here, load some more defines with macros
    # to help the build process

    ifeq ($(strip $(shell $(call file_exists,$(HELPERS_ROOT)/rsync_and_patch.mk))),found)
        include $(HELPERS_ROOT)/rsync_and_patch.mk
    else
        $(error Couldn't find the rsync_and_patch helper macro... Bailing out!)
    endif

    ifeq ($(strip $(shell $(call file_exists,$(HELPERS_ROOT)/build_stage.mk))),found)
        include $(HELPERS_ROOT)/build_stage.mk
    else
        $(error Couldn't find the build_stage helper macro... Bailing out!)
    endif

    ifeq ($(strip $(shell $(call file_exists,$(HELPERS_ROOT)/standard_buildf.mk))),found)
        include $(HELPERS_ROOT)/standard_buildf.mk
    else
        $(error Couldn't find the standard_buildf helper macro... Bailing out!)
    endif

    # Check the number of cores on the build machine
    NUM_CORES := $(strip $(shell $(call get_smt_cores)))
    ifeq ($(NUM_CORES),0)
        $(error Couldn't find the number of cores available... Bailing out!)
    endif

    # Load architecture dependent settings.
    ifeq ($(strip $(shell \
                      $(call file_exists, \
                             $(CONFIG)/arch/$(HOST_ARCH).$(BUILD_ARCH).mk))), \
                  found)
        include $(CONFIG)/arch/$(HOST_ARCH).$(BUILD_ARCH).mk
    else
        $(error Build on host $(HOST_ARCH) targeting $(BUILD_ARCH) is not supported.)
    endif


    ifneq ($(strip $(shell $(call create_remake))),created)
        $(error Failed to create remake.sh. Bailing out!)
    endif

    # Run distro sanity check to validate the build system
    ifdef distro_sanity
        ifeq ($(CROSS_BUILD),yes)
            AT_PKGS_CHECK := $(sort $(AT_CROSS_PKGS_REQ) $(AT_COMMON_PKGS_REQ))
            AT_PGMS_CHECK := $(sort $(AT_CROSS_PGMS_REQ) $(AT_COMMON_PGMS_REQ))
        else
            AT_PKGS_CHECK := $(sort $(AT_NATIVE_PKGS_REQ) $(AT_COMMON_PKGS_REQ))
            AT_PGMS_CHECK := $(sort $(AT_NATIVE_PGMS_REQ) $(AT_COMMON_PGMS_REQ))
        endif
        PKG_DISTRO_SANITY := $(strip $(shell $(call check_packages,$(AT_PKGS_CHECK))))
        PGM_DISTRO_SANITY := $(strip $(shell $(call check_programs,$(AT_PGMS_CHECK))))
        ifeq ($(PKG_DISTRO_SANITY),abort)
            $(error Missing critical requirements for the build process to proceed. Check ./sanity.log for a detailed missing requirements description.)
        endif
        ifeq ($(PGM_DISTRO_SANITY),abort)
            $(error Missing critical requirements for the build process to proceed. Check ./sanity.log for a detailed missing requirements description.)
        endif
    endif

    # Determine the BUILD_IGNORE_COMPAT if still undefined and set it based on
    # distro.mk AT_OLD_KERNEL. If AT_OLD_KERNEL isn't defined there, there is no
    # compatibility version to build to.
    ifeq ($(AT_OLD_KERNEL),)
        BUILD_IGNORE_COMPAT ?= yes
    else
        BUILD_IGNORE_COMPAT ?= no
    endif

    # If BUILD_IGNORE_AT_COMPAT if still undefined, we try to set it based on
    # a heuristics to check the requirement of its build. We must keep in mind
    # that there is no clear rule to dismiss the creation of this package, so in
    # this heuristics, we try to be as wide and loose as possible to include the
    # build of this package. If it's required *not* to build it, please be
    # explicit, setting this override on the build process itself, or on the global
    # build.mk or on the specific distro.mk file of the build.
    ifeq ($(BUILD_IGNORE_AT_COMPAT),)
        ifneq ($(AT_PREVIOUS_VERSION),)
            BUILD_IGNORE_AT_COMPAT := $(shell $(call build_at_compat_rpm))
        else
            BUILD_IGNORE_AT_COMPAT := yes
        endif
    endif

    # If it was defined that the atXX-compat rpm package should be build, we must
    # guarantee that there is a previous AT version defined to base this build. If
    # it is defined, we should set the variables used for the atXX-compat spec
    # file, otherwise, we must print a warning message and abort the build due to
    # missing critical information on the config files.
    ifneq ($(BUILD_IGNORE_AT_COMPAT),yes)
        ifeq ($(AT_PREVIOUS_VERSION),)
            $(warning No AT_PREVIOUS_VERSION defined, so we can't build the atXX-compat package.)
            $(warning If you need to do so, please configure the AT_PREVIOUS_VERSION properly and)
            $(warning run the build again.)
            $(error Aborting build due to missing required config information...)
        else
            BUILD_OLD_AT_VERSION := $(AT_PREVIOUS_VERSION)
            BUILD_OLD_AT_INSTALL := $(strip $(shell echo $(AT_DEST) | sed "s/$(AT_DIR_NAME)/at$(AT_PREVIOUS_VERSION)/"))
        endif
    endif

    # Determine the default system Toolchain to use
    ifeq ($(CROSS_BUILD),no)
        # Run a test compilation to verify the system toolchain
        DEFAULT_COMPILER := $(shell \
            echo "int main() { return 0; }" > ./sample.c; \
            $(SYSTEM_CC) ./sample.c; \
            echo $$(readelf -h a.out | grep "Class:" | sed 's|^.*ELF||'); \
            rm -f ./sample.c ./a.out \
        )
        # Find out which CPU we are doing the build
        AT_BUILD_CPU := $(shell cat /proc/cpuinfo | grep '^cpu' | cut -d ':' -f 2 | sort -u | sed 's@^ @@g' | cut -d ' ' -f 1 | tr [:upper:] [:lower:])
    else
        SYSTEM_CC := $(SYSTEM_CC) -m$(ENV_BUILD_ARCH)
        SYSTEM_CXX := $(SYSTEM_CXX) -m$(ENV_BUILD_ARCH)
        DEST_CROSS ?= $(strip $(shell $(call mkpath,$(AT_DEST)/ppc,no)))
    endif

    # Make sure the environment won't affect the build.
    # Under some circumstances if PYTHONPATH is defined, it may break the builds
    # or the tests of python and gdb.
    unexport PYTHONPATH

endif

# *********************************************************
# Finish setting build environment                    *****

# Continue processing for targets 'clone', 'edit' and 'pack'

# Directories where artifacts created by this system will be saved after
# running collect-artifacts.
ARTIFACTS := $(strip $(shell $(call mkpath,$(AT_BASE)/artifacts,yes)))

# Default
build_targets :=
.DEFAULT_GOAL := all

.PHONY: all test destclean cleanall clean collect clone edit pack

all: package release
	$(call collect_logs)

test: fvtr tarball_test

fvtr: $(RCPTS)/fvtr.rcpt

$(RCPTS)/fvtr.rcpt: $(RCPTS)/package.rcpt
	@echo "$$($(TIME)) Running FVTR for $(AT_VER_REV_INTERNAL)..."
	@+{ cd fvtr; \
	   AT_WD=$(AT_WD) \
	   AT_PREVIOUS_VERSION=$(AT_PREVIOUS_VERSION) \
	   AT_DIR_NAME=$(AT_DIR_NAME) \
	   ./fvtr.sh -f \
	             $(DYNAMIC_ROOT)/config_$(AT_VER_REV_INTERNAL).$(BUILD_ID) \
	             $(TEST_NAME) \
	             2>&1 \
	   | tee $(LOGS)/test-suite_$(AT_VER_REV_INTERNAL).$(BUILD_ID).log; \
	   test "$${PIPESTATUS[0]}" -eq "0"; \
	};

tarball_test: $(RCPTS)/source_tarball.rcpt
	@+{ echo "$$($(TIME)) Checking the source tarball..."; \
	    if [[ "$(CROSS_BUILD)" == "no" ]]; then \
	        $(call runandlog,$(LOGS)/_tarball_check.log,$(UTILITIES_ROOT)/check_tarball.sh $(AT_MAJOR_VERSION) $(SRC_TAR_FILE)); \
	        if [[ $${ret} -ne 0 ]]; then \
	            echo "Problem checking source tarball."; \
	            exit 1; \
	        fi; \
	    fi; \
	    echo "$$($(TIME)) Completed source tarball check!"; \
	};

clean: destclean

cleanall: destclean
	@echo "$$($(TIME)) Cleaning pristine sources and patches..."
	@echo "- $(FETCH_SOURCES)"
	@rm -rf $(FETCH_SOURCES)
	@echo "- $(FETCH_PATCHES)"
	@rm -rf $(FETCH_PATCHES)

destclean: localclean
	@echo "$$($(TIME)) Removing installation from $(AT_DEST)..."
	@echo "- $(AT_DEST)"
	@rm -rf $(AT_DEST)/*
	@+{ rmdir $(AT_DEST); \
	    if [[ -e $(AT_DEST) ]]; then \
	        echo "Cannot remove $(AT_DEST), trying as super-user..."; \
	        sudo rmdir $(AT_DEST); \
	    fi; \
	};

clean-fvtr: $(RCPTS)/collect-fvtr.rcpt
	@echo "$$($(TIME)) Cleaning FVTR logs... "
	@find fvtr/ -name '*.log' -delete
	@echo "$$($(TIME)) Cleaning FVTR output files... "
	@find fvtr/ -name '*.out*' -delete

clean-temp:
	@echo "$$($(TIME)) Cleaning $(TEMP_INSTALL)"
	@rm -rf ${TEMP_INSTALL}

localclean: collect clean-temp clean-fvtr
	@echo "$$($(TIME)) Cleaning build related folders..."
	@echo "- $(AT_WD)"
	@rm -rf $(AT_WD)
	@echo "- $(FETCH_SOURCES)/*.lock"
	@rm -rf $(FETCH_SOURCES)/*.lock
	@echo "- $(FETCH_PATCHES)/*.lock"
	@rm -rf $(FETCH_PATCHES)/*.lock
	@echo "- $(AT_BASE)/remake.sh"
	@rm -f $(AT_BASE)/remake.sh
	@echo "- $(AT_BASE)/sanity.log"
	@rm -f $(AT_BASE)/sanity.log

collect: collect-fvtr
	$(call collect_logs)

collect-fvtr: $(RCPTS)/collect-fvtr.rcpt

# Copy all generated files (packages, source code tarball, config file, logs,
# etc.) to the directory specified by ARTIFACTS.
# This is useful for the BuildBot in order to find all of these files in a
# standard place.
collect-artifacts:
	@echo "$$($(TIME)) Collecting artifacts..."
	@$(call copy_if_exists,$(CONFIG_EXPT),$(ARTIFACTS))
	@$(call copy_if_exists,$(AT_BASE)/sanity.log,$(ARTIFACTS))
	@$(call copy_if_exists,$(shell ls -t $(AT_BASE)/collected_logs-* \
	                         | head -n 1),\
	        $(ARTIFACTS));
	@$(call copy_if_exists,$(RELNOT_FILE),$(ARTIFACTS))
	@$(call copy_if_exists,$(SRC_TAR_FILE),$(ARTIFACTS))
	@{ \
	  for pkg in $(RPMS)/$(HOST_ARCH)/* $(DEBS)/*.deb; do \
	    $(call copy_if_exists,$${pkg},$(ARTIFACTS)); \
	  done; \
	  unset pkg; \
	}


# This rule updates the revision of all "config/source" files of AT to the
# latest commit. Alternatively, you may update a specific package, passing
# the name as a parameter. See update_revision.sh for more information.
#
# usage:
#      make DESTDIR=~ AT_CONFIGSET=next update-revision <package_name>
update-revision:
	@+{ packages=$(filter-out $@,$(MAKECMDGOALS)); \
	    if [[ -z "$${packages}" ]]; then \
	        packages="$(filter-out kernel,$(FETCH_PACKAGE_LIST))"; \
	    fi; \
	    for pkg in $${packages}; do \
	        . $(UTILITIES_ROOT)/update_revision.sh $(CONFIG)/packages/$${pkg}/sources; \
	    done; \
	}

# Defining an empty rule whenever update-revision is defined. This allows us to
# pass parameters to the update-revision rule.
ifeq (update-revision,$(firstword $(MAKECMDGOALS)))
%:
	@:
endif

clone:
	@+{ if [[ -n "$(FROM)" && -n "$(TO)" ]]; then \
	        echo "$$($(TIME)) Cloning config from $(FROM) to $(TO)..."; \
	        { pushd "$(CONFIG_ROOT)"; \
	          find $(FROM) -type d -print | sed 's/^$(FROM)*/$(TO)/g' | xargs mkdir -p; \
	          contents=$$(find $(FROM) ! -type d -print); \
	          for source in $${contents}; do \
	              target=$$(echo $${source} | sed 's/^$(FROM)/$(TO)/g'); \
	              if [[ -n "$$(echo $${source} | grep '\/distros\/.*$$')" ]]; then \
	                  if [[ -n "$$(ls -l $${source} | grep '^l')" ]]; then \
	                      if [[ -z "$$(readlink $${source} | grep -E '^\.\.\/')" ]]; then \
	                          cp -a $${source} $${target}; \
	                          continue; \
	                      fi; \
	                  fi; \
	              fi; \
	              if [[ -n "$$(echo $${source} | grep -e '\/base.mk' -e '\/build.mk' -e '\/sanity.mk')" ]]; then \
	                  cp -a $${source} $${target}; \
	                  continue; \
	              fi; \
	              prefix=$$(dirname $$(echo $${source} | sed -e 's/[^\/]\+\//\.\.\//g')); \
	              ln -sf $${prefix}/$${source} $${target}; \
	          done; \
	          popd; \
	        }  > /dev/null 2>&1; \
	    else \
	        echo "Please inform FROM=<version> TO=<version>."; \
	    fi; \
	}

edit:
	@+{ if [[ -n "$(FROM)" && -n "$(TYPE)" ]]; then \
	        echo "$$($(TIME)) Materializing config files of type $(TYPE) of config version $(FROM)..."; \
	        { pushd "$(CONFIG_ROOT)/$(FROM)/$(TYPE)"; \
	          if [[ -n "$(FILE)" ]]; then \
	              cp -L $(FILE) $(FILE).orig && rm -rf $(FILE) && mv $(FILE).orig $(FILE); \
	          else \
	              for file in $$(find . -type l -print); do \
	                  cp -L $${file} $${file}.orig && rm -rf $${file} && mv $${file}.orig $${file}; \
	              done; \
	          fi; \
	          popd; \
	        } > /dev/null 2>&1; \
	    else \
	        echo "Please inform at least FROM=<version> TYPE=<sublevel_type>."; \
	    fi; \
	}

# Generate a pack for usage on a build pack area
pack: hash
	@echo "$$($(TIME)) Preparing the build pack..."
	@+{ TMP_DIR=$$(mktemp -d "/tmp/atpack-XXXXXXX"); \
	    tar -cpvz -X "$(HELPERS_ROOT)/pack-exclude.lst" -f "$${TMP_DIR}/at-$(AT_TODAY).tgz" ./ > \
	        "$${TMP_DIR}/at-$(AT_TODAY).included"; \
	    mv "$${TMP_DIR}/at-$(AT_TODAY).tgz"      . ; \
	    mv "$${TMP_DIR}/at-$(AT_TODAY).included" . ; \
	    rm -rf "$${TMP_DIR}"; \
	} > /dev/null 2>&1
	@echo "$$($(TIME)) - Built pack tarball: at-$(AT_TODAY).tgz"
	@echo "$$($(TIME)) - Included file list: at-$(AT_TODAY).included"

# Update the commit.info with the branch/commit in use
hash:
	@+{ if [[ -d ./.git ]]; then \
	        echo "commit: $$(git rev-parse --short HEAD)" > commit.info; \
	        echo "branch: $$(git rev-parse --abbrev-ref HEAD)" >> commit.info; \
	        echo "File commit.info updated successfully."; \
	    else \
	        echo "No commit/branch info available. Are you running it from a build"; \
	        echo "pack area? Run it from a working git sandbox to collect usefull"; \
	        echo "values."; \
	    fi; \
	}

# Clean targets definitions
release: $(RCPTS)/release-notes.rcpt

# Select the packaging system
ifeq ($(DISTRO_FM),ubuntu)
  pack-sys := deb
endif
ifeq ($(DISTRO_FM),debian)
  pack-sys := deb
endif
ifeq ($(DISTRO_FM),redhat)
  pack-sys := rpm
endif
ifeq ($(DISTRO_FM),centos)
  pack-sys := rpm
endif
ifeq ($(DISTRO_FM),fedora)
  pack-sys := rpm
endif
ifeq ($(DISTRO_FM),suse)
  pack-sys := rpm
endif
ifeq ($(DISTRO_FM),opensuse)
  pack-sys := rpm
endif
ifeq ($(DISTRO_FM),unknown)
  $(error Unknown distribution. There is no packaging system available.)
endif

package: $(RCPTS)/package.rcpt

rpm: $(RCPTS)/rpm.rcpt

deb: $(RCPTS)/deb.rcpt

build: $(RCPTS)/build.rcpt

distributed_scripts: $(RCPTS)/distributed_scripts.rcpt

toolchain: $(RCPTS)/toolchain.rcpt

3rdparty_libs: $(RCPTS)/3rdparty_libs.rcpt

corelibs: $(RCPTS)/corelibs.rcpt

debug: $(RCPTS)/debug.rcpt

tuned: $(RCPTS)/tuned.rcpt

# Only append specific rules for targets other the 'clone', 'edit' and 'pack'
ifeq (,$(findstring $(MAKECMDGOALS),clone edit pack))

    # Include the rules for specific packages
    include $(CONFIG)/packages/*/*.mk

    # Rules to fetch the sources and patches of every package
    include $(SKELETONS_ROOT)/prefetch_target.mk

    # Create configuration file for the FVTR
    ifeq ($(strip $(shell $(call build_fvtr_conf,$(call get_built_packages)))),)
        $(error Failed to create the config file for the FVTR... Bailing out!)
    endif

endif

# Targets that need receipt generation

$(RCPTS)/package.rcpt: $(RCPTS)/$(pack-sys).rcpt $(RCPTS)/source_tarball.rcpt
	@touch $@

# Build and include the monitor (watch_ldconfig) utility
# RPM distros use a systemd service and DEB distros use a cronjob.
$(RCPTS)/monitor.rcpt: $(RCPTS)/toolchain.rcpt
	@echo "$$($(TIME)) Preparing the system's ld.so.cache monitor"
	@+{ $(AT_DEST)/bin/gcc -O2 -DAT_LDCONFIG_PATH=$(AT_DEST)/sbin/ldconfig \
	         $(SCRIPTS_ROOT)/utilities/watch_ldconfig.c -o $(AT_DEST)/bin/watch_ldconfig; \
	    echo "Monitor sucesfully compiled."; \
	    echo "Updating the SPEC files"; \
	    at_ver_rev_internal=$$( echo $(AT_VER_REV_INTERNAL) ); \
	    at_major_version=$$( echo $(AT_MAJOR_VERSION) ); \
	    group=$$( ls $(DYNAMIC_SPEC)/ | grep "toolchain\$$" ); \
	    echo "$(AT_DEST)/bin/watch_ldconfig" \
	          >> $(DYNAMIC_SPEC)/$${group}/ldconfig.filelist; \
	    if [[ $(USE_SYSTEMD) == "yes" ]]; then \
		systemd_unit=$$( pkg-config --variable=systemdsystemunitdir systemd ); \
		systemd_preset=$$( pkg-config --variable=systemdsystempresetdir systemd ); \
	        echo "$${systemd_unit}/$${at_ver_rev_internal//./}-cachemanager.service" \
	             >> $(DYNAMIC_SPEC)/$${group}/ldconfig.filelist; \
	        echo "$${systemd_preset}/90-$${at_ver_rev_internal//./}cachemanager.preset" \
	             >> $(DYNAMIC_SPEC)/$${group}/ldconfig.filelist; \
	    else \
		echo "/etc/cron.d/$${at_ver_rev_internal//./}_ldconfig" \
	             >> $(DYNAMIC_SPEC)/$${group}/ldconfig.filelist; \
	    fi; \
	    echo "All done."; \
	} &> $(LOGS)/_watch_ldconfig.log
	@touch $@

$(RCPTS)/toolchain.rcpt: $(RCPTS)/gcc_4.rcpt \
                         $(RCPTS)/tuned.rcpt
	@touch $@


$(RCPTS)/corelibs.rcpt: $(zlib_1-archdeps) \
                        $(openssl_1-archdeps) \
                        $(libauxv_1-archdeps) \
                        $(libhugetlbfs_1-archdeps) \
                        $(libvecpf_1-archdeps)
	@touch $@

# Cross builds don't require valgrind, neither oprofile
debug-reqs := $(valgrind_1-archdeps) $(oprofile_1-archdeps)

$(RCPTS)/debug.rcpt: $(gdb_1-archdeps) $(debug-reqs)
	@touch $@


# Generate release-notes
$(RCPTS)/release-notes.rcpt:
	@echo "$$($(TIME)) Begin generating the release-notes for $(AT_VER_REV_INTERNAL)..."
	@+{ echo "Building release-notes.$(AT_MAJOR).html"; \
	    export utilities=$(UTILITIES_ROOT); \
	    $(call runandlog,$(LOGS)/_release_notes_build.log,\
		   $(call build_release_notes,$(PACKAGES_LIST))); \
	    echo "Completed release-notes.$(AT_MAJOR).html build"; \
	} &> $(LOGS)/_release_notes.log
	@echo "$$($(TIME)) Completed release-notes for $(AT_VER_REV_INTERNAL)"
	@touch $@

# Extra libraries
$(RCPTS)/3rdparty_libs.rcpt: $(3rdparty_libs-reqs)
	@touch $@

# CPU-optimized libraries
$(RCPTS)/tuned.rcpt: $(tuned-targets)
	@touch $@


# DEB packages build
$(RCPTS)/deb.rcpt: $(RCPTS)/build.rcpt $(RCPTS)/distributed_scripts.rcpt
	@echo "$$($(TIME)) Begin DEB packaging for $(AT_FULL_VER)..."
	@+{ echo "Buiding DEB packages for $(AT_FULL_VER)."; \
	    export AT_STEPID=deb; \
	    echo "- Preparing the environment vars."; \
	    { $(call deb_setenv); } &> \
	        $(LOGS)/_$${AT_STEPID}-01_deb_setenv.log; \
	    echo "- Preparing the filelist of included packages..."; \
	    $(call runandlog,$(LOGS)/_$${AT_STEPID}-02_pkg_set_filelists.log, \
	           $(UTILITIES_ROOT)/pkg_build_filelists.sh $(TARGET)); \
	    if [[ $${ret} -ne 0 ]]; then \
	        echo "Failed while creating file lists."; \
	        exit 1; \
	    fi; \
	    echo "- Effectively build the requested DEBs..."; \
	    $(call runandlog,$(LOGS)/_$${AT_STEPID}-03_pkg_build_deb.log, \
	           $(UTILITIES_ROOT)/pkg_build_deb.sh); \
	    if [[ $${ret} -ne 0 ]]; then \
	        echo "Problem running pkg_build_deb.sh."; \
	        exit 1; \
	    fi; \
	    echo "Everything completed."; \
	} &> $(LOGS)/_deb.log
	@echo "$$($(TIME)) Completed DEB packages for $(AT_FULL_VER)"
	@touch $@


# RPM packages build
$(RCPTS)/rpm.rcpt: $(RCPTS)/build.rcpt $(RCPTS)/distributed_scripts.rcpt
	@echo "$$($(TIME)) Begin RPM packaging for $(AT_VER_REV_INTERNAL)..."
	@+{ echo "Buiding RPM packages for $(AT_VER_REV_INTERNAL)."; \
	    export AT_STEPID=rpm; \
	    echo "- Preparing the environment vars."; \
	    { $(call rpm_setenv); } &> \
		$(LOGS)/_$${AT_STEPID}-01_rpm_setenv.log; \
	    echo "- Preparing the filelist of included packages..."; \
	    $(call runandlog,$(LOGS)/_$${AT_STEPID}-02_pkg_build_filelists.log, \
	           $(UTILITIES_ROOT)/pkg_build_filelists.sh $(TARGET)); \
	    if [[ $${ret} -ne 0 ]]; then \
	        echo "Failed while creating file lists."; \
	        exit 1; \
	    fi; \
	    echo "- Building the required RPM packages..."; \
	    $(call runandlog,$(LOGS)/_$${AT_STEPID}-03_pkg_build_rpm.log, \
	           $(UTILITIES_ROOT)/pkg_build_rpm.sh); \
	    if [[ $${ret} -ne 0 ]]; then \
	        echo "Failed while creating file lists."; \
	        exit 1; \
	    fi; \
	    echo "Everything completed."; \
	} &> $(LOGS)/_rpm.log
	@echo "$$($(TIME)) Completed RPM packages for $(AT_VER_REV_INTERNAL)"
	@touch $@

# Create the source code tarball.
# We can't create it until the build is ready, because some stages apply
# patches to the source code.
$(RCPTS)/source_tarball.rcpt: $(RCPTS)/build.rcpt $(RCPTS)/distributed_scripts.rcpt
	@echo "$$($(TIME)) Begin to package source code for $(AT_VER_REV_INTERNAL)..."
	@+{ echo "Packing distributable sources in a tarball..."; \
	    $(call pack_source_pkgs,$(call get_built_packages)); \
	} &> $(LOGS)/_source_tarball.log
	@echo "$$($(TIME)) Completed packaging source code for $(AT_VER_REV_INTERNAL)"
	@touch $@

# Cross builds don't require compat, corelibs neither 3rdparty
ifeq ($(CROSS_BUILD),no)
    build-reqs := $(RCPTS)/corelibs.rcpt $(RCPTS)/3rdparty_libs.rcpt $(RCPTS)/monitor.rcpt
    ifneq ($(BUILD_IGNORE_COMPAT),yes)
        build-reqs += $(RCPTS)/glibc_compat.rcpt
    endif
endif
$(RCPTS)/build.rcpt: $(RCPTS)/toolchain.rcpt $(RCPTS)/debug.rcpt \
                     $(build-reqs) $(build_targets)
	@echo "$$($(TIME)) Running ldconfig with final configs on installed" \
	      "$(AT_VER_REV_INTERNAL)"
	@+{ set -x; \
	    if [[ "$(CROSS_BUILD)" == "no" ]]; then \
	        cat "$(DYNAMIC_LOAD)/sysinc.ld.conf" \
		    >> $(AT_DEST)/etc/ld.so.conf; \
	        $(AT_DEST)/sbin/ldconfig; \
	    fi; \
	    set +x; \
	} &> $(LOGS)/_build.log
	@echo "$$($(TIME)) Completed $(AT_VER_REV_INTERNAL) build"
	@touch $@


ifeq ($(BUILD_ENVIRONMENT_MODULES),yes)
    ENVIRONMENT_MODULES := $(RCPTS)/environment_modules.rcpt
endif

$(RCPTS)/environment_modules.rcpt: $(RCPTS)/build.rcpt
	@echo "$$($(TIME)) Creating and installing environment modules..."
	@mkdir -p $(AT_DEST)/share/modules/modulefiles
	@$(call runandlog,$(LOGS)/_environment_modules.log, \
	       $(UTILITIES_ROOT)/pkg_build_environment_modules.sh $(AT_DEST) \
	       $(AT_DIR_NAME) $(TARGET) \
	       $(DYNAMIC_SPEC)/main_toolchain/environment-modules.filelist \
	       $(CROSS_BUILD));
	@echo "$$($(TIME)) Completed install of environment modules!"
	@touch $@

$(RCPTS)/distributed_scripts.rcpt: $(ENVIRONMENT_MODULES)
	@echo "$$($(TIME)) Installing package scripts..."
	@+{ echo "Setting final destination for package scripts."; \
	    if [[ "$(CROSS_BUILD)" == "no" ]]; then \
	        mkdir -p $(AT_DEST)/scripts; \
	        echo "Copying package scripts there."; \
	        cp $(SCRIPTS_ROOT)/distributed/* $(AT_DEST)/scripts; \
	        echo "Completed copy."; \
	    fi; \
	} &> $(LOGS)/_distributed_scripts.log
	@echo "$$($(TIME)) Completed install of package scripts!"
	@touch $@


# Base toolchain build
ifeq ($(BUILD_IGNORE_COMPAT),no)
    ldconfig_2-reqs := $(glibc_compat-archdeps)
endif
$(RCPTS)/ldconfig_2.rcpt: $(glibc_2-archdeps) \
                          $(glibc_tuned-archdeps) \
                          $(libdfp_1-archdeps) \
                          $(libdfp_tuned-archdeps) \
                          $(zlib_1-archdeps) \
                          $(zlib_tuned-archdeps) \
                          $(ldconfig_2-reqs)
	@echo "$$($(TIME)) Second dynamic loader cache update..."
	@+{ echo "Run needed dependency"; \
	    if [[ "$(CROSS_BUILD)" == "no" ]]; then \
	        export AT_STEPID=ldconfig_2; \
	        $(call runandlog,$(LOGS)/_$${AT_STEPID}-1_ld.so.config.log,$(call prepare_loader_cache,2)); \
	        if [[ $${ret} -ne 0 ]]; then \
	            echo "Problem running the second ldconfig."; \
	            exit 1; \
	        fi; \
	    fi; \
	} &> $(LOGS)/_ldconfig_2.log
	@echo "$$($(TIME)) Completed second dynamic loader cache update!"
	@touch $@

$(RCPTS)/ldconfig_1.rcpt: $(glibc_1-archdeps)
	@echo "$$($(TIME)) First dynamic loader cache update..."
	@+{ echo "Run needed dependency"; \
	    if [[ "$(CROSS_BUILD)" == "no" ]]; then \
	        export AT_STEPID=ldconfig_1; \
	        $(call runandlog,$(LOGS)/_$${AT_STEPID}-1_ld.so.config.log,$(call prepare_loader_cache,1)); \
	        if [[ $${ret} -ne 0 ]]; then \
	            echo "Problem running first ldconfig."; \
	            exit 1; \
	       fi; \
	    fi; \
	} &> $(LOGS)/_ldconfig_1.log
	@echo "$$($(TIME)) Completed first dynamic loader cache update!"
	@touch $@

$(RCPTS)/%.b.rcpt: $(RCPTS)/%.a.rcpt
	@echo "$$($(TIME)) Starting the build of $(*F)..."
	@+{ echo "Checking dependencies"; \
	    pkg="$(shell echo $(*F) | grep -E -o '^[^_-]+_*' | grep -E -o '[^_-]+')"; \
	    stage_n="$(shell echo $(*F) | sed 's/.*_\([^._-]\+\)-\?.*/\1/g')"; \
	    bitsize="$(shell echo $(*F) | grep -E -o '\-[0-9]+' | grep -E -o '[0-9]+')"; \
	    echo "$(*F)" | grep tuned && tuned_target=yes; \
	    [[ -z "$${stage_n}" ]] && stage_n=1; \
	    echo "original=$(*F) p=$${pkg} s=$${stage_n} b=$${bitsize}"; \
	    echo "Setting basic environment for execution."; \
	    export AT_BASE=$(AT_BASE); \
	    export AT_WORK_PATH=$(SOURCE); \
	    export AT_KERNEL=$(AT_KERNEL); \
	    export AT_STEPID=$(*F); \
	    export AT_BIT_SIZE=$${bitsize}; \
	    if [[ "$${tuned_target}x" == "yesx" ]]; then \
		stage_file=stage_optimized; \
		export AT_OPTIMIZE_CPU=$${stage_n}; \
	    else \
		stage_file=stage_$${stage_n}; \
	    fi; \
	    echo "Preparing the build environment vars."; \
	    { $(call build_setenv); } &> \
			$(LOGS)/_$${AT_STEPID}-1_build_setenv.log; \
	    echo "Configuring source and build paths."; \
	    source $(CONFIG)/packages/$${pkg}/sources; \
	    echo "Setting the required stage configs."; \
	    source $(CONFIG)/packages/$${pkg}/$${stage_file}; \
	    echo "Preparing the build path and move there."; \
	    { $(call build_stage2,$${ATSRC_PACKAGE_WORK},$${ATCFG_BUILD_STAGE_T},$(*F)); } &> \
			$(LOGS)/_$${AT_STEPID}-2_build_stage.log; \
	    echo "Doing the actual build and install steps."; \
	    { source $(SCRIPTS_ROOT)/utils.sh; \
	      $(call standard_buildf); \
	    } &> $(LOGS)/_$${AT_STEPID}-3_standard_buildf.log; \
	    echo "Completed main build, cleaning it now."; \
	    { $(call clean_stage); } &> \
			$(LOGS)/_$${AT_STEPID}-5_clean_stage.log; \
	    echo "Everything completed."; \
	} &> $(LOGS)/_$(*F).log
	@echo "$$($(TIME)) Completed the build of $(*F)!"
	@touch $@

$(RCPTS)/bso_clearance.rcpt:
	@echo "$$($(TIME)) Checking and clearing the outbound BSO..."
	@bso_active=$$(curl http://www.ibm.com/us/en -s -k -o - | grep -o 'Firewall'); \
	if [[ "$${bso_active}" == "Firewall" ]]; then \
	    echo "BSO Firewall closed. Inform your credentials:"; \
	    echo -n "e-mail:   " && read USER_ID; \
	    echo -n "password: " && read -s USER_PASSWD; \
	    echo; \
	    curl https://www.ibm.com:443/ -s -k -o - \
	            -d "au_pxytimetag=$$(date +%s)&uname=$${USER_ID}&pwd=$${USER_PASSWD}&ok=OK" | \
	    sed -e 's:.*<H1>::g' -e 's:</H1>.*::g' -e 's:<[^>]*>:\n:g' | \
	    head -n 3; \
	fi
	@echo "$$($(TIME)) Completed the outbound BSO clearing!"
	@touch $@

$(RCPTS)/collect-fvtr.rcpt:
	@echo "$$($(TIME)) Collecting FVTR logs... "
	@find fvtr/ -name '*.log' -exec cp --parents -t $(LOGS) {} +
	@echo "$$($(TIME)) Completed collecting FVTR logs!"

$(RCPTS)/rsync_%.rcpt: $(RCPTS)/copy_%.rcpt \
                       $(RCPTS)/patch_%.rcpt
	@touch $@

$(RCPTS)/copy_%.rcpt: $(RCPTS)/fetch_%_source.rcpt \
                      $(RCPTS)/fetch_%_patches.rcpt
	@echo "$$($(TIME)) Starting $(*F) copy..."
	@+{ echo "Preparing the copy environemnt."; \
	    export AT_BASE=$(AT_BASE); \
	    export AT_KERNEL=$(AT_KERNEL); \
	    export AT_WORK_PATH=$(SOURCE); \
	    export AT_STEPID=copy_$(*F); \
	    source $(CONFIG)/packages/$(*F)/sources; \
	    echo "Copying the source code."; \
	    { $(call rsync_and_patch,$${ATSRC_PACKAGE_SRC},$${ATSRC_PACKAGE_WORK},$(FETCH_PATCHES),$${ATSRC_PACKAGE_PATCHES},$${ATSRC_PACKAGE_TARS},delete); } &> \
	                $(LOGS)/_$${AT_STEPID}-rsync_and_patch.log; \
	    if [[ -e $(TEMP_INSTALL)/$(*F)-copy-queue ]]; then \
	        echo "Copying patches."; \
	        cp -v -t $${ATSRC_PACKAGE_WORK} \
	              $$(cat $(TEMP_INSTALL)/$(*F)-copy-queue); \
	    fi; \
	} &> $(LOGS)/_copy_$(*F).log
	@echo "$$($(TIME)) Completed $(*F) copy!"
	@touch $@

$(RCPTS)/patch_%.rcpt: $(RCPTS)/copy_%.rcpt
	@echo "$$($(TIME)) Applying patches to $(*F)..."
	@+{ echo "Preparing the patch environment."; \
	    export AT_BASE=$(AT_BASE); \
	    export AT_KERNEL=$(AT_KERNEL); \
	    export AT_WORK_PATH=$(SOURCE); \
	    export AT_STEPID=patch_$(*F); \
	    source $(CONFIG)/packages/$(*F)/sources; \
	    if [[ "$$(type -t atsrc_apply_patches)" == "function" ]]; then \
	        echo "Applying patches."; \
	        pushd $${ATSRC_PACKAGE_WORK}; \
	        atsrc_apply_patches || exit 1; \
	        popd; \
	    else \
	        echo "$(*F) doesn't have patches."; \
	    fi; \
	} &> $(LOGS)/_patch_$(*F).log
	@echo "$$($(TIME)) Applied patches to $(*F)!"
	@touch $@

# Enable secondary expansion for the targets following the next one.
.SECONDEXPANSION:

# The following implicit target define the dependencies for optimized libraries.
$(RCPTS)/%.tuned.a.rcpt: $$($$(*F)-deps)
	@touch $@
# If your target don't require secondary expansion, avoid to add it after the
# target .SECONDEXPANSION.
# It won't fail, but will help to identify which targets require such kind of
# feature.
