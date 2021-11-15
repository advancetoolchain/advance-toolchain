# Copyright 2021 IBM Corporation
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
# Add support for relocation.
Prefix: %{_prefix}
Requires: advance-toolchain-%{at_major}__CROSS__-common = %{at_major_version}-%{at_revision_number}

%description
The IBM Advance Toolchain is a self-contained toolchain that provides
open-source compilers, runtime libraries, and development tools to take
advantage of the latest IBM Power hardware features on Linux.

####################################################
%package -n advance-toolchain-%{at_major}__CROSS__-common
Summary: Advance Toolchain - cross compiler common files
Group: Development
AutoReqProv: no
# Required to install info manuals.
Requires(post): info
Requires(preun): info
# Add support for relocation.
Prefix: %{_prefix}

%description -n advance-toolchain-%{at_major}__CROSS__-common
The IBM Advance Toolchain is a self-contained toolchain that provides
open-source compilers, runtime libraries, and development tools to take
advantage of the latest IBM Power hardware features on Linux.
This package provides common files for the Advance Toolchain.

####################################################
%package runtime-extras
Summary: Advance Toolchain - extra runtime files
Group: Development/Libraries
AutoReqProv: no
Requires: %{name} = %{at_major_version}-%{at_revision_number}
# Add support for relocation.
Prefix: %{_prefix}

%description runtime-extras
The IBM Advance Toolchain is a self-contained toolchain that provides
open-source compilers, runtime libraries, and development tools to take
advantage of the latest IBM Power hardware features on Linux.
This package contains the runtime libraries to run programs built with the
Advance Toolchain that are not present in the main cross compiler package.

####################################################
%package mcore-libs
Summary: Advance Toolchain
Group: Development/Libraries
Requires: %{name} = %{at_major_version}-%{at_revision_number}, __MCORE-LIBS_REQ__
AutoReqProv: no
Provides: advance-toolchain-mcore-libs = %{at_major_version}-%{at_revision_number}

%description mcore-libs
The IBM Advance Toolchain is a self-contained toolchain that provides
open-source compilers, runtime libraries, and development tools to take
advantage of the latest IBM Power hardware features on Linux.
This package provides the necessary libraries to build multi-threaded applications
using the specialized multi-threaded libraries Boost, SPHDE, URCU and Threading
Building Blocks.


####################################################

# On newer rpm versions, it's common to strip debug info and to compile python
# files. We only want to compress man pages.
%define __os_install_post /usr/lib/rpm/brp-compress

# Relative paths of directories.
%define datadir_r share
%define infodir_r share/info
# Some distributions set this to 'lib64' by default.
%define libdir_r lib
%define libexecdir_r libexec
%define mandir_r share/man
%define tgtinfodir_r __DEST_CROSS_REL__/usr/share/info
%define tgtmandir_r __DEST_CROSS_REL__/usr/share/man

# These have been known to be different on different distributions.
%define _datadir %{_prefix}/%{datadir_r}
%define _infodir %{_prefix}/%{infodir_r}
%define _libdir %{_prefix}/%{libdir_r}
%define _libexecdir %{_prefix}/%{libexecdir_r}
%define _mandir %{_prefix}/%{mandir_r}
%define _tgtinfodir %{_prefix}/%{tgtinfodir_r}
%define _tgtmandir %{_prefix}/%{tgtmandir_r}

%prep
%build
%install
mkdir -p ${RPM_BUILD_ROOT}$(dirname %{_prefix})
cp -af %{_prefix} ${RPM_BUILD_ROOT}$(dirname %{_prefix})
# Remove info/dir from installation dir
rm -f ${RPM_BUILD_ROOT}%{_infodir}/dir \
      ${RPM_BUILD_ROOT}%{_tgtinfodir}/dir
# Compress all of the info files.
gzip -9nvf ${RPM_BUILD_ROOT}%{_infodir}/*.info*
gzip -9nvf ${RPM_BUILD_ROOT}%{_tgtinfodir}/*.info*

################################################
%post
# Update the info directory entries
for INFO in $(ls ${RPM_INSTALL_PREFIX}/%{tgtinfodir_r}/*.info.gz); do
	install-info ${INFO} ${RPM_INSTALL_PREFIX}/%{tgtinfodir_r}/dir
done
datadir="${RPM_INSTALL_PREFIX}/%{datadir_r}"
if [[ -w /usr/share/modules/modulefiles/. ]]; then
	ln -sf ${datadir}/modules/modulefiles/%{at_dir_name}-%{target} \
		/usr/share/modules/modulefiles/.
fi
if [[ -w /usr/share/Modules/modulefiles/. ]]; then
	ln -sf ${datadir}/modules/modulefiles/%{at_dir_name}-%{target} \
		/usr/share/Modules/modulefiles/.
fi
################################################

#################### common ####################
%post -n advance-toolchain-%{at_major}__CROSS__-common
# Update the info directory entries
for INFO in $(ls ${RPM_INSTALL_PREFIX}/%{infodir_r}/*.info.gz); do
	install-info ${INFO} ${RPM_INSTALL_PREFIX}/%{infodir_r}/dir
done
# Make the environment modules visible to users.
if [[ ! ( -d /usr/share/modules/modulefiles || \
	  -d /usr/share/Modules/modulefiles ) ]]; then
	# for SUSE family
	mkdir -p /usr/share/modules/modulefiles
	# for Red Hat family
	mkdir -p /usr/share/Modules/modulefiles
fi
datadir="${RPM_INSTALL_PREFIX}/%{datadir_r}"
for mdir in modules Modules; do
	if [[ -w /usr/share/$mdir/modulefiles/. ]]; then
		cat <<EOF >/usr/share/$mdir/modulefiles/%{at_dir_name}
#%Module1.0
set AT_VERSION "%{at_dir_name}"
proc ModulesHelp { } {
	global AT_VERSION
	puts stderr "Environment for using IBM Advance Toolchain \$AT_VERSION"
}
module-whatis "Environment for using IBM Advance Toolchain \$AT_VERSION"

prepend-path PATH "${RPM_INSTALL_PREFIX}/bin"
prepend-path INFOPATH "${RPM_INSTALL_PREFIX}/share/info"
prepend-path MANPATH "${RPM_INSTALL_PREFIX}/share/man"
EOF
	fi
done
################################################

#################### runtime-extras ############
%post runtime-extras
# Update the info directory entries
for INFO in $(ls ${RPM_INSTALL_PREFIX}/%{infodir_r}/*.info.gz); do
	install-info ${INFO} ${RPM_INSTALL_PREFIX}/%{infodir_r}/dir
done
################################################

#################### mcore-libs ################
%post mcore-libs
# Do this in every .spec file because they may only install a subset.
# We never know the order rpm is going to update AT's packages.
# So we only need to update the ldconf cache when ldconfig is available
if [[ -f %{_sbindir}/ldconfig ]]; then
	%{_sbindir}/ldconfig
fi
################################################

%preun
# Update the info directory entries
if [ "$1" = 0 ]; then
	for INFO in $(ls ${RPM_INSTALL_PREFIX}/%{tgtinfodir_r}/*.info.gz); do
		install-info --delete ${INFO} \
			${RPM_INSTALL_PREFIX}/%{tgtinfodir_r}/dir
	done
fi
################################################

#################### common ####################
%preun -n advance-toolchain-%{at_major}__CROSS__-common
# Update the info directory entries
if [ "$1" = 0 ]; then
	# Remove the global link to the environment modules.
	rm -f /usr/share/modules/modulefiles/%{at_dir_name}
	rm -f /usr/share/Modules/modulefiles/%{at_dir_name}
	for INFO in $(ls ${RPM_INSTALL_PREFIX}/%{infodir_r}/*.info.gz); do
		install-info --delete ${INFO} \
			     ${RPM_INSTALL_PREFIX}/%{infodir_r}/dir
	done
fi
################################################

#################### runtime-extras ############
%preun runtime-extras
# Update the info directory entries
if [ "$1" = 0 ]; then
	for INFO in $(ls ${RPM_INSTALL_PREFIX}/%{tgtinfodir_r}/*.info.gz); do
		install-info --delete ${INFO} \
			${RPM_INSTALL_PREFIX}/%{tgtinfodir_r}/dir
	done
fi
################################################
%postun
if [[ ${1} -eq 0 ]]; then
	find ${RPM_INSTALL_PREFIX} -type d -empty -delete
	# Remove the global link to the environment modules.
	rm -f /usr/share/modules/modulefiles/%{at_dir_name}-%{target}
	rm -f /usr/share/Modules/modulefiles/%{at_dir_name}-%{target}
fi
################################################

#################### common ####################
%postun -n advance-toolchain-%{at_major}__CROSS__-common
if [[ ${1} -eq 0 ]]; then
	find ${RPM_INSTALL_PREFIX} -type d -empty -delete
fi
################################################

#################### runtime-extras ############
%postun runtime-extras
if [[ ${1} -eq 0 ]]; then
	find ${RPM_INSTALL_PREFIX} -type d -empty -delete
fi
################################################

#################### mcore-libs ################
%postun mcore-libs
# Update the loader cache after uninstall
# We never know the order rpm is going to remove/update AT's packages.
# So we only need to update the ldconf cache when ldconfig is still available
if [[ -f %{_sbindir}/ldconfig ]]; then
    %{_sbindir}/ldconfig
fi
################################################

%files -f %{at_work}/cross.list
%defattr(-,root,root)

%files -n advance-toolchain-%{at_major}__CROSS__-common -f %{at_work}/cross-common.list

%files runtime-extras -f %{at_work}/cross-runtime-extras.list
%defattr(-,root,root)

%files mcore-libs -f %{at_work}/mcore-libs.list
%defattr(-,root,root)
