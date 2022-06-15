# Copyright 2020 IBM Corporation
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
# Distro dependent basic definitions for Ubuntu 20.04 LTS
# =======================================================
# This Makefile include contains the definitions for the distro being used
# for the build process. It contains kernel version infos and distro specific
# sanity checks.

# Informs the distro supported power archs
AT_SUPPORTED_ARCHS := ppc64le

# You may force the BUILD_IGNORE_AT_COMPAT general condition by distro
#BUILD_IGNORE_AT_COMPAT := yes

# Kernel version to build toolchain against
# - As this distro only supports one arch variation (ppc64le), there is no
#   need to conditionally define these versions based on arch.
AT_KERNEL := 5.4   # Current distro kernel version for runtime.
# TODO: fill this when our packaging system starts supporting runtime-compat
# on Ubuntu.
#AT_OLD_KERNEL :=  # Previous distro kernel version for runtime-compat.

# Inform the mainly supported distros
AT_SUPPORTED_DISTROS := focal

# Inform the compatibility supported distros
#AT_COMPAT_DISTROS :=

# Sign the repository and packages
#AT_SIGN_PKGS := yes
#AT_SIGN_REPO := yes
#AT_SIGN_PKGS_CROSS := no
#AT_SIGN_REPO_CROSS := yes

# ID of GNUPG key used to sign our packages (main/compat)
AT_GPG_KEYID := 6976A827
AT_GPG_KEYIDC := 3052930D
# ID of GNUPG key used to sign our repositories (main/compat)
AT_GPG_REPO_KEYID := 3052930D
AT_GPG_REPO_KEYIDC := 3052930D

# Options required by the command to update the repository metadata
AT_REPOCMD_OPTS := -p -s sha256 --simple-md-filenames --no-database

# As some distros have special requirements for configuration upon final
# AT installation, put in this macro, the final configurations required
# after the main build and prior to the rpm build
define distro_final_config
    echo "nothing to do."
endef

# Inform the list of packages to check
ifndef AT_DISTRO_REQ_PKGS
    AT_CROSS_PKGS_REQ :=
    # TODO: add libqt4-dev or libqt5-dev when it will be available in Ubuntu 20.04.
    AT_NATIVE_PKGS_REQ := libxslt libpopt-dev \
                          libc6-dev libbz2-dev xsltproc docbook-xsl \
                          libsqlite3-dev liblzma-dev libcrypt-dev
    AT_COMMON_PKGS_REQ := zlib1g-dev libncurses5-dev ncurses-term flex bison \
                          texinfo gawk fakeroot debhelper \
                          autoconf rsync curl bc libxml2-utils automake \
                          dpkg-sig xutils-dev libtool wget dh-systemd \
                          docbook2x pkg-config autoconf-archive make \
                          libffi-dev python3 git systemtap-sdt-dev
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
