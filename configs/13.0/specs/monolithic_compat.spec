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
%description
The IBM Advance Toolchain is a self-contained toolchain that provides
open-source compilers, runtime libraries, and development tools to take
advantage of the latest IBM Power hardware features on Linux.

####################################################
%package runtime-compat
Summary: Advance Toolchain
Requires: __COMPAT_REQ__
Conflicts: advance-toolchain-%{at_major}-runtime
Group: Development/Libraries
AutoReqProv: no

%description runtime-compat
The IBM Advance Toolchain is a self-contained toolchain that provides
open-source compilers, runtime libraries, and development tools to take
advantage of the latest IBM Power hardware features on Linux.


####################################################
# On newer rpm versions, it's common to strip debug info and to compile python
# files. We only want to compress man pages.
%define __os_install_post /usr/lib/rpm/brp-compress

# These have been known to be different on different distributions
%define _bindir %{_prefix}/bin
%define _sbindir %{_prefix}/sbin
%define _scriptdir %{_prefix}/scripts
%define _libexecdir %{_prefix}/libexec
# Some distributions set this to 'lib64' by default
%define _libdir %{_prefix}/lib

# Compat packages may use different variables with same values.
%define _compatprefix %{_prefix}
%define _compatbindir %{_prefix}/bin
%define _compatdatadir %{_datadir}
%define _compatlibdir %{_prefix}/lib
%define _compatlibexecdir %{_prefix}/libexec
%define _compatsbindir %{_prefix}/sbin

%prep

%build

%install
mkdir -p ${RPM_BUILD_ROOT}/$(dirname %{_prefix})
# Make compat the root dir.
cp -af %{_prefix}/compat ${RPM_BUILD_ROOT}/%{_prefix}
# Remove loader temporary files from rpm build install tree
rm -rf ${RPM_BUILD_ROOT}/%{_prefix}/etc/ld.so.cache \
       ${RPM_BUILD_ROOT}/%{_prefix}/etc/ldconfig.log
# Ensure runtime-compat won't distribute header files (usually kernel headers,
# necessary for building glibc).
rm -rf ${RPM_BUILD_ROOT}/%{_prefix}/include/

####################################################
%pre runtime-compat
_host_power_arch=$(LD_SHOW_AUXV=1 /bin/true | grep AT_PLATFORM | grep -i power | sed 's/.*power//')
if [[ "${_host_power_arch}" != "" && "${_host_power_arch}" < "%{_min_power_arch}" ]]; then
    echo "The system is power${_host_power_arch} but must be at least power%{_min_power_arch} to install this RPM."
    exit 1
fi

####################################################
%post runtime-compat
# Do this in every .spec file because they may only install a subset.
%{_prefix}/sbin/ldconfig



####################################################
%postun runtime-compat
# Remove the directory only when uninstalling
if [[ "${1}" -eq "0" ]]; then
    if [[ -d %{_prefix} ]]; then
        rm -rf %{_prefix}
    fi
fi
# Only remove ldconfig if it's' a bash script file
if file /usr/sbin/ldconfig | grep "bash script" > /dev/null; then
    at_installs=$(find /opt/ -maxdepth 1 -type d -name 'at[0-9].[0-9]*' \
        2>/dev/null | wc -l)
    if [[ "${at_installs}" -eq "0" ]]; then
        rm -f /usr/sbin/ldconfig
    fi
fi


####################################################
%files runtime-compat -f %{at_work}/compat.list
%defattr(-,root,root)
