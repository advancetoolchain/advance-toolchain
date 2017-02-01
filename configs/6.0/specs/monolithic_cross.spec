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
# Required to install info manuals.
Requires(post): info
Requires(preun): info

%description
The advance toolchain is a self contained toolchain which provides preview
toolchain functionality in GCC, binutils, GLIBC, and GDB.

# On newer rpm versions, it's common to strip debug info and to compile python
# files. We only want to compress man pages.
%define __os_install_post /usr/lib/rpm/brp-compress

# These have been known to be different on different distributions
%define _mandir %{_prefix}/share/man
%define _infodir %{_prefix}/share/info
%define _tgtmandir __DEST_CROSS__/usr/share/man
%define _tgtinfodir __DEST_CROSS__/usr/share/info
%define _libexecdir %{_prefix}/libexec
%define _datadir %{_prefix}/share
%define _mandir %{_prefix}/share/man
%define _infodir %{_prefix}/share/info
# Some distributions set this to 'lib64' by default
%define _libdir %{_prefix}/lib

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
	if [[ -d "%{_prefix}" ]]; then
		rm -rf %{_prefix}
	fi
fi

%post
# Update the info directory entries
for INFO in $(ls %{_infodir}/*.info.gz); do
	install-info ${INFO} %{_infodir}/dir > /dev/null 2>&1 || :
done
for INFO in $(ls %{_tgtinfodir}/*.info.gz); do
	install-info ${INFO} %{_tgtinfodir}/dir > /dev/null 2>&1 || :
done

%preun
# Update the info directory entries
if [ "$1" = 0 ]; then
	for INFO in $(ls %{_infodir}/*.info.gz); do
		install-info --delete ${INFO} %{_infodir}/dir > /dev/null 2>&1 || :
	done
	for INFO in $(ls %{_tgtinfodir}/*.info.gz); do
		install-info --delete ${INFO} %{_tgtinfodir}/dir > /dev/null 2>&1 || :
	done
fi


%files -f %{at_work}/cross_files.list
%defattr(-,root,root)
