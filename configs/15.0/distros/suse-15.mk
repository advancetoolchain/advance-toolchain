# Copyright 2019 IBM Corporation
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
# Distro dependent basic definitions for SuSE Enterprise Server 12
# ================================================================
# This Makefile include contains the definitions for the distro being used
# for the build process. It contains kernel version infos and distro specific
# sanity checks.

# Informs the distro supported power archs
AT_SUPPORTED_ARCHS := ppc64le

# You may force the BUILD_IGNORE_AT_COMPAT general condition by distro
#BUILD_IGNORE_AT_COMPAT := yes

AT_OLD_KERNEL :=         # Previous distro kernel version for runtime-compat.

# Inform the mainly supported distros
AT_SUPPORTED_DISTROS := SLES_15

# Inform the compatibility supported distros
AT_COMPAT_DISTROS :=

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
AT_GPG_REPO_KEYIDC := 6976A827
AT_GPG_REPO_KEYIDL := 6976A827

# Options required by the command to update the repository metadata
AT_REPOCMD_OPTS := -p

# Moved here from build.mk since the value for this variable
# depends on the distro.
# For a cross build the executables in the toolchain (gcc, ld, etc.)
# should be built as 64 bit.
BUILD_CROSS_32 := no

# As some distros have special requirements for configuration upon final
# AT installation, put in this macro, the final configurations required
# after the main build and prior to the rpm build
define distro_final_config
    echo "nothing to do."
endef

# Inform the list of packages to check
ifndef AT_DISTRO_REQ_PKGS
    AT_CROSS_PKGS_REQ :=
    AT_NATIVE_PKGS_REQ := libxslt popt-devel docbook-xsl-stylesheets \
                          libbz2-devel sqlite3-devel libxcrypt-devel
    AT_COMMON_PKGS_REQ := zlib-devel ncurses-devel flex bison texinfo \
                          createrepo_c gawk autoconf rsync curl \
                          bc automake rpm-build gcc-c++ xorg-x11-util-devel \
                          docbook2x wget autoconf-archive make git \
                          libffi-devel python3 systemtap-sdt-devel
    AT_CROSS_PGMS_REQ :=
    AT_NATIVE_PGMS_REQ :=
    AT_COMMON_PGMS_REQ :=
endif

# If needed, define the necessary distro related sanity checks.
define distro_sanity
    echo "nothing to test here"
endef

# Inform if the systemd service to monitor the loader cache should be used.
USE_SYSTEMD := yes
