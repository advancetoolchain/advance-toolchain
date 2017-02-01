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
# Add support for relocation.
Prefix: %{_prefix}
# Required to install info manuals.
Requires(post): info
Requires(preun): info

%description
The advance toolchain is a self contained toolchain which provides preview
toolchain functionality in GCC, binutils, GLIBC, and GDB.

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


%postun
if [[ ${1} -eq 0 ]]; then
	if [[ -d "${RPM_INSTALL_PREFIX}" ]]; then
		rm -rf ${RPM_INSTALL_PREFIX}
	fi
fi

%post
# Update the info directory entries
for INFO in $(ls ${RPM_INSTALL_PREFIX}/%{infodir_r}/*.info.gz); do
	install-info ${INFO} ${RPM_INSTALL_PREFIX}/%{infodir_r}/dir
done
for INFO in $(ls ${RPM_INSTALL_PREFIX}/%{tgtinfodir_r}/*.info.gz); do
	install-info ${INFO} ${RPM_INSTALL_PREFIX}/%{tgtinfodir_r}/dir
done

%preun
# Update the info directory entries
if [ "$1" = 0 ]; then
	for INFO in $(ls ${RPM_INSTALL_PREFIX}/%{infodir_r}/*.info.gz); do
		install-info --delete ${INFO} \
			     ${RPM_INSTALL_PREFIX}/%{infodir_r}/dir
	done
	for INFO in $(ls ${RPM_INSTALL_PREFIX}/%{tgtinfodir_r}/*.info.gz); do
		install-info --delete ${INFO} \
			     ${RPM_INSTALL_PREFIX}/%{tgtinfodir_r}/dir
	done
fi

%files -f %{at_work}/cross_files.list
%defattr(-,root,root)
