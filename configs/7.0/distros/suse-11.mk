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
# Distro dependent basic definitions for SuSE Enterprise Server 11
# ================================================================
# This Makefile include contains the definitions for the distro being used
# for the build process. It contains kernel version infos and distro specific
# sanity checks.

# Informs the distro supported power archs
AT_SUPPORTED_ARCHS := ppc64

# You may force the BUILD_IGNORE_AT_COMPAT general condition by distro
#BUILD_IGNORE_AT_COMPAT := yes

# Kernel version to build toolchain against
# SLES 11 was released with Linux 2.6.27 however, PAFLib requires a feature
# that is only available on 2.6.32.
# - As this distro only supports one arch variation (ppc64), there is no
#   need to conditionally define these versions based on arch.
AT_KERNEL := 2.6.32       # Current distro kernel version for runtime.
AT_OLD_KERNEL := 2.6.16   # Previous distro kernel version for runtime-compat.

# Inform the mainly supported distros
AT_SUPPORTED_DISTROS := SLES_11

# Inform the compatibility suported distros
AT_COMPAT_DISTROS := SLES_10

# Sign the repository and packages
AT_SIGN_PKGS := yes
AT_SIGN_REPO := yes
AT_SIGN_PKGS_CROSS := no
AT_SIGN_REPO_CROSS := yes

# ID of GNUPG key used to sign our packages (main/compat)
AT_GPG_KEYID  := 3052930D
AT_GPG_KEYIDC := 3052930D
AT_GPG_KEYIDL := 3052930D
# ID of GNUPG key used to sign our repositories (main/compat)
AT_GPG_REPO_KEYID  := 3052930D
AT_GPG_REPO_KEYIDC := 3052930D
AT_GPG_REPO_KEYIDL := 3052930D

# Options required by the command to update the repository metadata
AT_REPOCMD_OPTS := -p

# As some distros have special requirements for configuration upon final
# AT installation, put in this macro, the final configurations required
# after the main build and prior to the rpm build
define distro_final_config
    echo "nothing to do."
endef

# Inform the list of packages to check
ifndef AT_DISTRO_REQ_PKGS
    AT_CROSS_PKGS_REQ :=
    AT_NATIVE_PKGS_REQ := \(ibm-java2-ppc64-sdk-5.0\|java-1.5.0-ibm-devel\) \
                          libxslt popt-devel docbook-xsl-stylesheets \
                          xorg-x11-util-devel readline readline-devel
    AT_COMMON_PKGS_REQ := zlib-devel ncurses-devel flex bison texinfo \
                          createrepo subversion cvs gawk autoconf rsync curl \
                          bc automake wget
    AT_CROSS_PGMS_REQ :=
    AT_NATIVE_PGMS_REQ :=
    AT_COMMON_PGMS_REQ := git_1.7
    AT_JAVA_VERSIONS := 5
endif

# If needed, define the necessary distro related sanity checks.
define distro_sanity
    echo "nothing to test here"
endef

# Inform if the systemd service to monitor the loader cache should be used.
USE_SYSTEMD := no
