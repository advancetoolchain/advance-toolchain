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
%description
The IBM Advance Toolchain is a self-contained toolchain that provides
open-source compilers, runtime libraries, and development tools to take
advantage of the latest IBM Power hardware features on Linux.

####################################################
%package runtime
Summary: Advance Toolchain
Requires: __RUNTIME_REQ__
Requires(pre): coreutils
Requires(pre): gawk
Requires(pre): grep
Requires(pre): rpm
Requires(pre): sed
Requires(post): systemd
Requires(preun): systemd
Requires(postun): grep
Requires(postun): systemd
Group: Development/Libraries
AutoReqProv: no
Provides: advance-toolchain-runtime = %{at_major_version}-%{at_revision_number}
BuildRequires: systemd

%description runtime
The IBM Advance Toolchain is a self-contained toolchain that provides
open-source compilers, runtime libraries, and development tools to take
advantage of the latest IBM Power hardware features on Linux.


####################################################
%package devel
Summary: Advance Toolchain
Requires: advance-toolchain-%{at_major}-runtime = %{at_major_version}-%{at_revision_number}, __DEVEL_REQ__
Group: Development/Libraries
AutoReqProv: no
Provides: advance-toolchain-devel = %{at_major_version}-%{at_revision_number}

%description devel
The IBM Advance Toolchain is a self-contained toolchain that provides
open-source compilers, runtime libraries, and development tools to take
advantage of the latest IBM Power hardware features on Linux.
This package provides the packages necessary to build applications that use the
features provided by the Advance Toolchain.


####################################################
%package mcore-libs
Summary: Advance Toolchain
Requires: advance-toolchain-%{at_major}-runtime = %{at_major_version}-%{at_revision_number}, __MCORE-LIBS_REQ__
Group: Development/Libraries
AutoReqProv: no
Provides: advance-toolchain-mcore-libs = %{at_major_version}-%{at_revision_number}

%description mcore-libs
The IBM Advance Toolchain is a self-contained toolchain that provides
open-source compilers, runtime libraries, and development tools to take
advantage of the latest IBM Power hardware features on Linux.
This package provides the necessary libraries to build multi-threaded applications
using the specialized multi-threaded libraries Amino-CBB, URCU and Threading
Building Blocks.


####################################################
%package perf
Summary: Advance Toolchain
Requires: advance-toolchain-%{at_major}-devel = %{at_major_version}-%{at_revision_number}, __PROFILE_REQ__
Group: Development/Libraries
AutoReqProv: no
Provides: advance-toolchain-perf = %{at_major_version}-%{at_revision_number}

%description perf
The IBM Advance Toolchain is a self-contained toolchain that provides
open-source compilers, runtime libraries, and development tools to take
advantage of the latest IBM Power hardware features on Linux.
This 'perf' package contains the performance library install targets
for Valgrind.


####################################################
%package libnxz
Summary: Advance Toolchain
Requires: advance-toolchain-%{at_major}-devel = %{at_major_version}-%{at_revision_number}, __LIBNXZ_REQ__
Group: Development/Libraries
AutoReqProv: no
Provides: advance-toolchain-libnxz = %{at_major_version}-%{at_revision_number}

%description libnxz
The IBM Advance Toolchain is a self-contained toolchain that provides
open-source compilers, runtime libraries, and development tools to take
advantage of the latest IBM Power hardware features on Linux.
This package provides the NX GZIP Library.


####################################################
%package selinux
Summary: Advance Toolchain
Requires: advance-toolchain-%{at_major}-runtime = %{at_major_version}-%{at_revision_number}
Requires(post): /usr/sbin/semanage, /sbin/restorecon
Requires(postun): /usr/sbin/semanage, /sbin/restorecon
Group: Development/Libraries

%description selinux
The IBM Advance Toolchain is a self-contained toolchain that provides
open-source compilers, runtime libraries, and development tools to take
advantage of the latest IBM Power hardware features on Linux.
The 'selinux' package contains the required labels for a system running SElinux.


####################################################
%package runtime-debuginfo
Summary: Debug information for package %{name}-runtime
Requires: advance-toolchain-%{at_major}-runtime = %{at_major_version}-%{at_revision_number}
Requires(post): grep
Group: Development/Debug
AutoReqProv: 0

%description runtime-debuginfo
This package provides debug information for package %{name}-runtime.
Debug information is useful when developing applications that use this
package or when debugging this package.

%package mcore-libs-debuginfo
Summary: Debug information for package %{name}-mcore-libs
Requires: advance-toolchain-%{at_major}-mcore-libs = %{at_major_version}-%{at_revision_number}
Group: Development/Debug
AutoReqProv: 0

%description mcore-libs-debuginfo
This package provides debug information for package %{name}-mcore-libs.
Debug information is useful when developing applications that use this
package or when debugging this package.

%package devel-debuginfo
Summary: Debug information for package %{name}-devel
Requires: advance-toolchain-%{at_major}-devel = %{at_major_version}-%{at_revision_number}
Requires(post): grep
Group: Development/Debug
AutoReqProv: 0

%description devel-debuginfo
This package provides debug information for package %{name}-devel.
Debug information is useful when developing applications that use this
package or when debugging this package.

%package perf-debuginfo
Summary: Debug information for package %{name}-perf
Requires: advance-toolchain-%{at_major}-perf = %{at_major_version}-%{at_revision_number}
Requires(post): grep
Group: Development/Debug
AutoReqProv: 0

%description perf-debuginfo
This package provides debug information for package %{name}-perf.
Debug information is useful when developing applications that use this
package or when debugging this package.

%package libnxz-debuginfo
Summary: Debug information for package %{name}-libnxz
Requires: advance-toolchain-%{at_major}-libnxz = %{at_major_version}-%{at_revision_number}
Requires(post): grep
Group: Development/Debug
AutoReqProv: 0

%description libnxz-debuginfo
This package provides debug information for package %{name}-libnxz.
Debug information is useful when developing applications that use this
package or when debugging this package.

%global __debug_package 1


####################################################
# Compress man pages and strip debug information into separate packages.
%define __os_install_post \
        /usr/lib/rpm/brp-compress \
%{nil}
%define __debug_install_post \
        bash %{_rpmdir}/find-debuginfo.sh %{?_find_debuginfo_opts} "%{_builddir}/%{?buildsubdir}" \
        bash %{_rpmdir}/split-debuginfo.sh --rpmdir %{_rpmdir} --dynamic %{at_work} --subpackage runtime \
        bash %{_rpmdir}/split-debuginfo.sh --rpmdir %{_rpmdir} --dynamic %{at_work} --subpackage mcore-libs \
        bash %{_rpmdir}/split-debuginfo.sh --rpmdir %{_rpmdir} --dynamic %{at_work} --subpackage devel \
        bash %{_rpmdir}/split-debuginfo.sh --rpmdir %{_rpmdir} --dynamic %{at_work} --subpackage libnxz \
        bash %{_rpmdir}/split-debuginfo.sh --rpmdir %{_rpmdir} --dynamic %{at_work} --subpackage profile \
%{nil}

# Relative paths of directories.
%define datadir_r share

# These have been known to be different on different distributions
%define _datadir %{_prefix}/share
%define _libexecdir %{_prefix}/libexec
%define _mandir %{_prefix}/share/man
%define _infodir %{_prefix}/share/info
%define _scriptdir %{_prefix}/scripts
# Some distributions set this to 'lib64' by default
%define _libdir %{_prefix}/lib
%define _bindir %{_prefix}/bin

%prep
# Do not include createldhuge-1.0.sh and restoreld.sh.
rm -rf %{_scriptdir}/createldhuge-1.0.sh %{_scriptdir}/restoreld.sh

%build

%install
# Prepare a new build sandbox area
mkdir -p ${RPM_BUILD_ROOT}$(dirname %{_prefix})
cp -af %{_prefix} ${RPM_BUILD_ROOT}$(dirname %{_prefix})
# Remove ld.so.cache from rpm build install tree
rm -rf ${RPM_BUILD_ROOT}%{_prefix}/compat \
       ${RPM_BUILD_ROOT}%{_prefix}/etc/ld.so.cache \
       ${RPM_BUILD_ROOT}%{_prefix}/etc/ldconfig.log
# Copy the compatibility init script to the correct place
mkdir -p ${RPM_BUILD_ROOT}/etc/rc.d/init.d
# Remove info/dir from installation dir
rm ${RPM_BUILD_ROOT}%{_infodir}/dir
# Compress all of the info files.
gzip -9nvf ${RPM_BUILD_ROOT}%{_infodir}/*.info*
# Set a systemd service to run AT's ldconfig when the system's ldconfig is \
# executed.
systemd_unit=$(pkg-config --variable=systemdsystemunitdir systemd)
systemd_preset=$(pkg-config --variable=systemdsystempresetdir systemd)
mkdir -p ${RPM_BUILD_ROOT}/${systemd_unit}/
sed -e s:__AT_VER_REV_INTERNAL__:%{at_ver_rev_internal}: \
    -e s:__AT_DEST__:%{_prefix}: %{_rpmdir}/cachemanager.service \
    > ${RPM_BUILD_ROOT}/${systemd_unit}/%{at_ver_alternative}-cachemanager.service
mkdir -p ${RPM_BUILD_ROOT}/${systemd_preset}/
echo "enable %{at_ver_alternative}-cachemanager.service" \
    > ${RPM_BUILD_ROOT}/${systemd_preset}/90-%{at_ver_alternative}cachemanager.preset

####################################################
%pre runtime
_host_power_arch=$(LD_SHOW_AUXV=1 /bin/true | grep AT_PLATFORM | grep -i power | sed 's/.*power//')
if [[ "${_host_power_arch}" != "" \
      && "%{_min_power_arch}" != $(echo -e "%{_min_power_arch}\n${_host_power_arch}" | sort -V | head -n 1) ]]; then
    echo "The system is power${_host_power_arch} but must be at least power%{_min_power_arch} to install this RPM."
    exit 1
fi
# Get distro glibc installed version
GLIBC_VER=$(rpm -q --queryformat='%{VERSION}\n' glibc | sort -u)
GLIBC_ABS=$(echo "${GLIBC_VER}" | awk 'BEGIN { FS="." }; { print $1$2 }' -)
if [[ ${GLIBC_ABS} -gt %{at_glibc_ver} ]]; then
    echo "Your current glibc version ${GLIBC_VER} is higher than the one provided by the Advance Toolchain glibc."
    echo "Please, consider the possibility of installing a newer version of Advance Toolchain."
fi

####################################################
%post runtime
# Automatically set the timezone
rm -f %{_prefix}/etc/localtime
ln -s /etc/localtime %{_prefix}/etc/localtime
if [[ -n "$(command -v systemctl)" && "$(systemctl is-system-running)" != "offline" ]]; then
	systemctl preset %{at_ver_alternative}-cachemanager.service \
	    > /dev/null 2>&1 || :
	systemctl restart %{at_ver_alternative}-cachemanager.service
fi

#---------------------------------------------------
%post devel
# Update the info directory entries
for INFO in $(ls %{_infodir}/*.info.gz); do
    install-info ${INFO} %{_infodir}/dir > /dev/null 2>&1 || :
done
# Run this setup script right after install
%{_prefix}/scripts/at-create-ibmcmp-cfg.sh
# Make the environment module visible to users.
if [[ ! ( -d /usr/share/modules/modulefiles || \
	  -d /usr/share/Modules/modulefiles ) ]]; then
	# for SUSE family
	mkdir -p /usr/share/modules/modulefiles
	# for Red Hat family
	mkdir -p /usr/share/Modules/modulefiles
fi
if [[ -w /usr/share/modules/modulefiles/. ]]; then
	ln -sf %{_datadir}/modules/modulefiles/%{at_dir_name} \
		/usr/share/modules/modulefiles/.
fi
if [[ -w /usr/share/Modules/modulefiles/. ]]; then
	ln -sf %{_datadir}/modules/modulefiles/%{at_dir_name} \
		/usr/share/Modules/modulefiles/.
fi

#---------------------------------------------------
%post selinux
semanage fcontext -a -t etc_t '%{_prefix}/etc(/.*)?' 2>/dev/null
semanage fcontext -a -t ld_so_cache_t '%{_prefix}/etc/ld.so.cache' 2>/dev/null
semanage fcontext -a -t locale_t '%{_prefix}/etc/localtime' 2>/dev/null
restorecon -R %{_prefix}/etc
semanage fcontext -a -t locale_t '%{_prefix}/share/locale/locale.alias' \
    2>/dev/null
restorecon -R %{_prefix}/share/locale
semanage fcontext -a -t locale_t '%{_prefix}/share/zoneinfo/Factory' \
    2>/dev/null
restorecon -R %{_prefix}/share/zoneinfo

#---------------------------------------------------
%post runtime-debuginfo
# Create symlinks to the debuginfo files in .debug subdirectories so valgrind,
# gdb, and perf can find the symbols.
for DIR in $(find %{_prefix}/lib/debug/%{_prefix}/*/ -type d \
             | grep -v build-id); do
    dest=${DIR#%{_prefix}/lib/debug}
    mkdir -p ${dest}/.debug/
    ln -sf ${DIR}/* ${dest}/.debug/
    for FILE in $(ls -1 ${DIR}/*.debug 2>/dev/null); do
        ln -sf ${FILE} ${dest}/.debug/$(basename ${FILE} .debug)
    done
done

#---------------------------------------------------
%post devel-debuginfo
# Create symlinks to the debuginfo files in .debug subdirectories so valgrind,
# gdb, and perf can find the symbols.
for DIR in $(find %{_prefix}/lib/debug/%{_prefix}/*/ -type d \
             | grep -v build-id); do
    dest=${DIR#%{_prefix}/lib/debug}
    mkdir -p ${dest}/.debug/
    ln -sf ${DIR}/* ${dest}/.debug/
    for FILE in $(ls -1 ${DIR}/*.debug 2>/dev/null); do
        ln -sf ${FILE} ${dest}/.debug/$(basename ${FILE} .debug)
    done
done

#---------------------------------------------------
%post mcore-libs-debuginfo
# Create symlinks to the debuginfo files in .debug subdirectories so valgrind,
# gdb, and perf can find the symbols.
for DIR in $(find %{_prefix}/lib/debug/%{_prefix}/*/ -type d \
             | grep -v build-id); do
    dest=${DIR#%{_prefix}/lib/debug}
    mkdir -p ${dest}/.debug/
    ln -sf ${DIR}/* ${dest}/.debug/
    for FILE in $(ls -1 ${DIR}/*.debug 2>/dev/null); do
        ln -sf ${FILE} ${dest}/.debug/$(basename ${FILE} .debug)
    done
done

#---------------------------------------------------
%post perf-debuginfo
# Create symlinks to the debuginfo files in .debug subdirectories so valgrind,
# gdb, and perf can find the symbols.
for DIR in $(find %{_prefix}/lib/debug/%{_prefix}/*/ -type d \
             | grep -v build-id); do
    dest=${DIR#%{_prefix}/lib/debug}
    mkdir -p ${dest}/.debug/
    ln -sf ${DIR}/* ${dest}/.debug/
    for FILE in $(ls -1 ${DIR}/*.debug 2>/dev/null); do
        ln -sf ${FILE} ${dest}/.debug/$(basename ${FILE} .debug)
    done
done

#---------------------------------------------------
%post libnxz-debuginfo
# Create symlinks to the debuginfo files in .debug subdirectories so valgrind,
# gdb, and perf can find the symbols.
for DIR in $(find %{_prefix}/lib/debug/%{_prefix}/*/ -type d \
             | grep -v build-id); do
    dest=${DIR#%{_prefix}/lib/debug}
    mkdir -p ${dest}/.debug/
    ln -sf ${DIR}/* ${dest}/.debug/
    for FILE in $(ls -1 ${DIR}/*.debug 2>/dev/null); do
        ln -sf ${FILE} ${dest}/.debug/$(basename ${FILE} .debug)
    done
done

####################################################
%posttrans runtime
# Do this in every .spec file because they may only install a subset.
# We never know the order rpm is going to update AT's packages.
# So we only need to update the ldconf cache when ldconfig is available
if [[ -f %{_sbindir}/ldconfig ]]; then
    %{_sbindir}/ldconfig
fi

#---------------------------------------------------
%posttrans devel
# Do this in every .spec file because they may only install a subset.
# We never know the order rpm is going to update AT's packages.
# So we only need to update the ldconf cache when ldconfig is available
if [[ -f %{_sbindir}/ldconfig ]]; then
    %{_sbindir}/ldconfig
fi

#---------------------------------------------------
%posttrans perf
# Do this in every .spec file because they may only install a subset.
# We never know the order rpm is going to update AT's packages.
# So we only need to update the ldconf cache when ldconfig is available
if [[ -f %{_sbindir}/ldconfig ]]; then
    %{_sbindir}/ldconfig
fi

#---------------------------------------------------
%posttrans mcore-libs
# Do this in every .spec file because they may only install a subset.
# We never know the order rpm is going to update AT's packages.
# So we only need to update the ldconf cache when ldconfig is available
if [[ -f %{_sbindir}/ldconfig ]]; then
    %{_sbindir}/ldconfig
fi

#---------------------------------------------------
%posttrans libnxz
# Do this in every .spec file because they may only install a subset.
# We never know the order rpm is going to update AT's packages.
# So we only need to update the ldconf cache when ldconfig is available
if [[ -f %{_sbindir}/ldconfig ]]; then
    %{_sbindir}/ldconfig
fi

####################################################
%preun devel
# Update the info directory entries
if [ "$1" = 0 ]; then
    for INFO in $(ls %{_infodir}/*.info.gz); do
        install-info --delete ${INFO} %{_infodir}/dir > /dev/null 2>&1 || :
    done
fi

#---------------------------------------------------
%preun runtime
if [[ -n "$(command -v systemctl)" && "$(systemctl is-system-running)" != "offline" ]]; then
    systemctl --no-reload disable --now \
    %{at_ver_alternative}-cachemanager.service > /dev/null 2>&1 || :
fi
####################################################
%postun runtime
# Remove the directory only when uninstalling
if [[ ${1} -eq 0 ]]; then
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

if [[ -n "$(command -v systemctl)" && "$(systemctl is-system-running)" != "offline" ]]; then
    systemctl try-restart %{at_ver_alternative}-cachemanager.service >/dev/null \
    2>&1 || :
fi
#---------------------------------------------------
%postun devel
if [ "$1" = 0 ]; then
	# Remove the global link to the environment module.
	rm -f /usr/share/modules/modulefiles/%{at_dir_name} 
	rm -f /usr/share/Modules/modulefiles/%{at_dir_name} 
fi
# Update the loader cache after uninstall
# We never know the order rpm is going to remove/update AT's packages.
# So we only need to update the ldconf cache when ldconfig is still available
if [[ -f %{_sbindir}/ldconfig ]]; then
    %{_sbindir}/ldconfig
fi

#---------------------------------------------------
%postun perf
# Update the loader cache after uninstall
# We never know the order rpm is going to remove/update AT's packages.
# So we only need to update the ldconf cache when ldconfig is still available
if [[ -f %{_sbindir}/ldconfig ]]; then
    %{_sbindir}/ldconfig
fi

#---------------------------------------------------
%postun mcore-libs
# Update the loader cache after uninstall
# We never know the order rpm is going to remove/update AT's packages.
# So we only need to update the ldconf cache when ldconfig is still available
if [[ -f %{_sbindir}/ldconfig ]]; then
    %{_sbindir}/ldconfig
fi

#---------------------------------------------------
%postun selinux
if [ $1 -eq 0 ] ; then  # final removal
    semanage fcontext -d -t locale_t '%{_prefix}/share/zoneinfo/Factory' \
        2>/dev/null
    restorecon -R %{_prefix}/share/zoneinfo
    semanage fcontext -d -t locale_t \
        '%{_prefix}/share/locale/locale.alias' 2>/dev/null
    restorecon -R %{_prefix}/share/locale
    semanage fcontext -d -t locale_t '%{_prefix}/etc/localtime' 2>/dev/null
    semanage fcontext -d -t ld_so_cache_t '%{_prefix}/etc/ld.so.cache' \
        2>/dev/null
    semanage fcontext -d -t etc_t '%{_prefix}/etc(/.*)?' 2>/dev/null
    restorecon -R %{_prefix}/etc
fi

%postun runtime-debuginfo
# Delete symlinks to the now-deleted debuginfo files in .debug subdirectories.
find -L %{_prefix} -path '*/.debug/*' -type l -exec rm -f {} \;

%postun devel-debuginfo
# Delete symlinks to the now-deleted debuginfo files in .debug subdirectories.
find -L %{_prefix} -path '*/.debug/*' -type l -exec rm -f {} \;

%postun mcore-libs-debuginfo
# Delete symlinks to the now-deleted debuginfo files in .debug subdirectories.
find -L %{_prefix} -path '*/.debug/*' -type l -exec rm -f {} \;

%postun perf-debuginfo
# Delete symlinks to the now-deleted debuginfo files in .debug subdirectories.
find -L %{_prefix} -path '*/.debug/*' -type l -exec rm -f {} \;

%postun libnxz-debuginfo
# Delete symlinks to the now-deleted debuginfo files in .debug subdirectories.
find -L %{_prefix} -path '*/.debug/*' -type l -exec rm -f {} \;

####################################################
%files runtime -f %{at_work}/runtime.list
%defattr(-,root,root)
# Config script for XLC/XLF.
%{_scriptdir}/at-create-ibmcmp-cfg.sh
# Get the requirements for a RPM package.
%{_scriptdir}/find_dependencies.sh
# Dynamic TLE helper script.
%{_scriptdir}/tle_on.sh

# License text for the scripts distributed in the package.
%license %{_scriptdir}/LICENSE

#---------------------------------------------------
%files devel -f %{at_work}/devel.list
%defattr(-,root,root)

#---------------------------------------------------
%files perf -f %{at_work}/profile.list
%defattr(-,root,root)

#---------------------------------------------------
%files mcore-libs -f %{at_work}/mcore-libs.list
%defattr(-,root,root)

#---------------------------------------------------
%files libnxz -f %{at_work}/libnxz.list
%defattr(-,root,root)

#---------------------------------------------------
%files selinux

#---------------------------------------------------
%files runtime-debuginfo -f debugfiles-runtime.list
%defattr(-,root,root)

#---------------------------------------------------
%files mcore-libs-debuginfo -f debugfiles-mcore-libs.list
%defattr(-,root,root)

#---------------------------------------------------
%files devel-debuginfo -f debugfiles-devel.list
%defattr(-,root,root)

#---------------------------------------------------
%files perf-debuginfo -f debugfiles-profile.list
%defattr(-,root,root)

#---------------------------------------------------
%files libnxz-debuginfo -f debugfiles-libnxz.list
%defattr(-,root,root)
