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
%description
The IBM Advance Toolchain is a self-contained toolchain that provides
open-source compilers, runtime libraries, and development tools to take
advantage of the latest IBM Power hardware features on Linux.

####################################################
%package runtime-at__AT_OLD_VER__-compat
Summary: Advance Toolchain
Conflicts: advance-toolchain-at__AT_OLD_VER__-runtime
Requires: advance-toolchain-%{at_major}-runtime = %{at_major_version}-%{at_revision_number}
Requires(post): /sbin/chkconfig
Requires(preun): /sbin/chkconfig
Requires(preun): /sbin/service
Requires(postun): /sbin/service
Group: Development/Libraries

%description runtime-at__AT_OLD_VER__-compat
The IBM Advance Toolchain is a self-contained toolchain that provides
open-source compilers, runtime libraries, and development tools to take
advantage of the latest IBM Power hardware features on Linux.
This package provides a runtime compatibility mode for programs compiled with
version __AT_OLD_VER__ of the Advance Toolchain.

####################################################
# On newer rpm versions, it's common to strip debug info and to compile python
# files. We only want to compress man pages.
%define __os_install_post /usr/lib/rpm/brp-compress

%prep

%build

%install
# Prepare a new build sandbox area
mkdir -p ${RPM_BUILD_ROOT}$(dirname %{_prefix})
# Prepare the required directories for install
if [[ ! -d "${RPM_BUILD_ROOT}/etc/rc.d/init.d" ]]; then
    mkdir -p ${RPM_BUILD_ROOT}/etc/rc.d/init.d
fi
mv %{_rpmdir}/%{at_major}-runtime-at__AT_OLD_VER__-compat \
   ${RPM_BUILD_ROOT}/etc/rc.d/init.d/
chmod +x ${RPM_BUILD_ROOT}/etc/rc.d/init.d/%{at_major}-runtime-at__AT_OLD_VER__-compat
mkdir -p ${RPM_BUILD_ROOT}__AT_OLD_DEST__/lib \
         ${RPM_BUILD_ROOT}__AT_OLD_DEST__/lib64

%post runtime-at__AT_OLD_VER__-compat
/sbin/chkconfig --add %{at_major}-runtime-at__AT_OLD_VER__-compat

%preun runtime-at__AT_OLD_VER__-compat
if [ $1 -eq 0 ] ; then
    /sbin/service %{at_major}-runtime-at__AT_OLD_VER__-compat stop \
        >/dev/null 2>&1
    /sbin/chkconfig --del %{at_major}-runtime-at__AT_OLD_VER__-compat
fi

%postun runtime-at__AT_OLD_VER__-compat
if [ "$1" -ge "1" ] ; then
    /sbin/service %{at_major}-runtime-at__AT_OLD_VER__-compat condrestart \
        >/dev/null 2>&1 || :
fi

####################################################
%files runtime-at__AT_OLD_VER__-compat
%defattr(-,root,root)
/etc/rc.d/init.d/%{at_major}-runtime-at__AT_OLD_VER__-compat
__AT_OLD_DEST__/lib
__AT_OLD_DEST__/lib64
