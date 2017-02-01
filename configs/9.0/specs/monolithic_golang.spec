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
Name: advance-toolchain
Version: %{at_major_version}
Release: %{at_revision_number}
License: GPL, LGPL
Group: Development/Libraries
Summary: Advance Toolchain

%description
The advance toolchain is a self contained toolchain which provides preview
toolchain functionality in GCC, binutils and GLIBC, as well as the debug and
profile tools GDB, Valgrind and OProfile.
It also provides a group of optimized threading libraries as well.

####################################################
%package golang-at
Summary: Golang for ppc64le
AutoReqProv: no
Provides: advance-toolchain-golang = %{at_major_version}-%{at_revision_number}


%description golang-at
The advance toolchain is a self contained toolchain which provides preview
toolchain functionality in GCC, binutils, GLIBC, GDB, Valgrind, and OProfile.
The 'golang' package contains the Golang binaries for ppc64le.

####################################################
# On newer rpm versions, it's common to strip debug info and to compile python
# files. We only want to compress man pages.
%define __os_install_post /usr/lib/rpm/brp-compress

%prep

%build

%install
# Prepare a build sandbox area for golang
mkdir -p ${RPM_BUILD_ROOT}$(dirname %{_golang})
cp -af %{_tmpdir}/golang_1/%{_golang} ${RPM_BUILD_ROOT}$(dirname %{_golang})

####################################################
%files golang-at -f %{at_work}/golang.list
%defattr(-,root,root)
