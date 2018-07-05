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
# Distro dependent basic definitions for RedHat Enterprise Server 7
# =================================================================
# This Makefile include contains the definitions for the distro being used
# for the build process. It contains kernel version infos and distro specific
# sanity checks.

# Informs the distro supported power archs
AT_SUPPORTED_ARCHS := ppc64 ppc64le

# You may force the BUILD_IGNORE_AT_COMPAT general condition by distro
#BUILD_IGNORE_AT_COMPAT := yes

# Kernel version to build toolchain against
# - As this distro may support any arch variation combination (ppc64le/ppc64),
#   there is a need to conditionally define these versions based on arch.
ifeq ($(BUILD_ARCH),ppc64le)
    # Current distro kernel version for runtime.
    AT_KERNEL := 3.10
    # Previous distro kernel version for runtime-compat.
    AT_OLD_KERNEL :=
else
    # Current distro kernel version for runtime.
    AT_KERNEL := 3.10
    # Previous distro kernel version for runtime-compat.
    AT_OLD_KERNEL := 2.6.32
endif

# Inform the mainly supported distros
AT_SUPPORTED_DISTROS := RHEL7

# Inform the compatibility supported distros
AT_COMPAT_DISTROS := RHEL6

# Sign the repository and packages
AT_SIGN_PKGS := yes
AT_SIGN_REPO := yes
AT_SIGN_PKGS_CROSS := no
AT_SIGN_REPO_CROSS := yes

# ID of GNUPG key used to sign our packages (main/compat)
AT_GPG_KEYID  := 6976A827
AT_GPG_KEYIDC := 6976A827
AT_GPG_KEYIDL := 6976A827
# ID of GNUPG key used to sign our repositories (main/compat)
AT_GPG_REPO_KEYID  := 6976A827
AT_GPG_REPO_KEYIDC := 3052930D
AT_GPG_REPO_KEYIDL := 6976A827

# Options required by the command to update the repository metadata
AT_REPOCMD_OPTS := -p -s sha1 --simple-md-filenames --no-database

# Moved here from build.mk since the value for this variable
# depends on the distro.
# For a cross build the executables in the toolchain (gcc, ld, etc.)
# should be built as 32 bit.
BUILD_CROSS_32 := no

# As some distros have special requirements for configuration upon final
# AT installation, put in this macro, the final configurations required
# after the main build and prior to the rpm build
define distro_final_config
    echo "nothing to do."
endef

# Due to a problem found on RHEL 7.0 GA there is a package that doesn't fall
# into the default dependencies and should be added manually for checking here
# libstdc++-static (in this case, either i686 and x86_64) must be available for
# the build to proceed. If RedHat fixes its internal dependencies later on,
# this check could be safely removed.

# Inform the list of packages to check
ifndef AT_DISTRO_REQ_PKGS
    AT_CROSS_PKGS_REQ :=
    AT_NATIVE_PKGS_REQ := libxslt docbook-style-xsl qt-devel \
                          autogen-libopts sqlite-devel
    AT_COMMON_PKGS_REQ := zlib-devel ncurses-devel flex bison texinfo \
                          createrepo glibc-devel subversion cvs gawk \
                          rsync curl bc automake libstdc\\+\\+-static \
                          redhat-lsb-core autoconf bzip2-[0-9] libtool-[0-9] \
                          gzip rpm-build-[0-9] rpm-sign gcc-c++ imake wget \
                          docbook2X
    AT_CROSS_PGMS_REQ :=
    AT_NATIVE_PGMS_REQ :=
    AT_COMMON_PGMS_REQ := git_1.7
    AT_JAVA_VERSIONS := 7
endif

# Complete the list of packages to check that are based on arch being build
ifeq ($(BUILD_ARCH),ppc64le)
    AT_NATIVE_PKGS_REQ += \(ibm-java2-ppc64le-sdk-7.1\|java-1.7.1-ibm-devel\)
    AT_NATIVE_PKGS_REQ += glibc-devel bzip2-devel popt-devel
else
    AT_NATIVE_PKGS_REQ += \(ibm-java2-ppc64-sdk-7.0\|java-1.7.1-ibm-devel\) \
                          glibc-devel-.*\.ppc$$ glibc-devel-.*\.ppc64$$ \
                          bzip2-devel-.*\.ppc$$ bzip2-devel-.*\.ppc64$$ \
                          popt-devel-.*\.ppc$$ popt-devel-.*\.ppc64$$
endif

# If needed, define the necessary distro related sanity checks.
define distro_sanity
    echo "nothing to test here"
endef
# Inform if the systemd service to monitor the loader cache should be used.
USE_SYSTEMD := yes
