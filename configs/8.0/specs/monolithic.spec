%description
The advance toolchain is a self contained toolchain which provides preview
toolchain functionality in GCC, binutils and GLIBC, as well as the debug and
profile tools GDB, Valgrind and OProfile.
It also provides a group of optimized threading libraries as well.

####################################################
%package runtime
Summary: Advance Toolchain
Requires: __RUNTIME_REQ__
Group: Development/Libraries
AutoReqProv: no
Provides: advance-toolchain-runtime = %{at_major_version}-%{at_revision_number}

%description runtime
The advance toolchain is a self contained toolchain which provides preview
toolchain functionality in GCC, binutils, GLIBC, GDB, Valgrind, and OProfile.


####################################################
%package devel
Summary: Advance Toolchain
Requires: advance-toolchain-%{at_major}-runtime = %{at_major_version}-%{at_revision_number}, __DEVEL_REQ__
Group: Development/Libraries
AutoReqProv: no
Provides: advance-toolchain-devel = %{at_major_version}-%{at_revision_number}

%description devel
The advance toolchain is a self contained toolchain which provides preview
toolchain functionality in GCC, binutils, GLIBC, GDB, Valgrind, and OProfile.
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
The advance toolchain is a self contained toolchain which provides preview
toolchain functionality in GCC, binutils, GLIBC, GDB, Valgrind, and OProfile.
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
The advance toolchain is a self contained toolchain which provides preview
toolchain functionality in GCC, binutils, GLIBC, GDB, Valgrind, and OProfile.
This package 'perf' package contains the performance library install targets
for Valgrind and OProfile.


####################################################
%package selinux
Summary: Advance Toolchain
Requires: advance-toolchain-%{at_major}-runtime = %{at_major_version}-%{at_revision_number}
Requires(post): /usr/sbin/semanage, /sbin/restorecon
Requires(postun): /usr/sbin/semanage, /sbin/restorecon
Group: Development/Libraries

%description selinux
The advance toolchain is a self contained toolchain which provides preview
toolchain functionality in GCC, binutils, GLIBC, GDB, Valgrind, and OProfile.
The 'selinux' package contains the required labels for a system
running SElinux.


####################################################
# On newer rpm versions, it's common to strip debug info and to compile python
# files. We only want to compress man pages.
%define __os_install_post /usr/lib/rpm/brp-compress

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
# Do not include find_dependencies.sh on AT < 9.0.
rm -rf %{_scriptdir}/find_dependencies.sh

# Do not include tle_on.sh on AT < 9.0.
rm -rf %{_scriptdir}/tle_on.sh

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
# Set a cronjob to run AT's ldconfig when the system's ldconfig is executed.
mkdir -p ${RPM_BUILD_ROOT}/etc/cron.d/
echo "@reboot root %{_bindir}/watch_ldconfig &" \
      > ${RPM_BUILD_ROOT}/etc/cron.d/%{at_ver_rev_internal}_ldconfig

####################################################
%pre runtime
_host_power_arch=$(LD_SHOW_AUXV=1 /bin/true | grep AT_PLATFORM | grep -i power | sed 's/.*power//')
if [[ "${_host_power_arch}" != "" && "${_host_power_arch}" < "%{_min_power_arch}" ]]; then
    echo "The system is power${_host_power_arch} but must be at least power%{_min_power_arch} to install this RPM."
    exit 1
fi
# Get distro glibc installed version
GLIBC_VER=$(rpm -q --queryformat='%{VERSION}\n' glibc | sort -u)
GLIBC_ABS=$(echo "${GLIBC_VER}" | awk 'BEGIN { FS="." }; { print $1$2 }' -)
if [[ ${GLIBC_ABS} -gt %{at_glibc_ver} ]]; then
    echo "Your current glibc version ${GLIBC_VER} is higher than the one provided by the advance toolchain glibc."
    echo "Please, consider the possibility of installing a newer version of advance toolchain."
fi

#---------------------------------------------------
%pre perf
# We need to create this special user for OProfile
getent group oprofile >/dev/null || groupadd -r oprofile
getent passwd oprofile >/dev/null || \
useradd -r -g oprofile -d /home/oprofile -s /sbin/nologin \
-c "Special user account to be used by OProfile" oprofile
exit 0


####################################################
%post runtime
# Automatically set the timezone
rm -f %{_prefix}/etc/localtime
ln -s /etc/localtime %{_prefix}/etc/localtime
# Do this in every .spec file because they may only install a subset.
# We never know the order rpm is going to update AT's packages.
# So we only need to update the ldconf cache when ldconfig is available
if [[ -f %{_sbindir}/ldconfig ]]; then
    %{_sbindir}/ldconfig
fi
echo "AT's linker cache file is not automatically updated when a package is \
installed or modified."
echo "Please run %{_bindir}/watch_ldconfig or reboot your system if you want \
it to be."

#---------------------------------------------------
%post devel
# Update the info directory entries
for INFO in $(ls %{_infodir}/*.info.gz); do
    install-info ${INFO} %{_infodir}/dir > /dev/null 2>&1 || :
done
# Run this setup script right after install
%{_prefix}/scripts/at-create-ibmcmp-cfg.sh
# Do this in every .spec file because they may only install a subset.
# We never know the order rpm is going to update AT's packages.
# So we only need to update the ldconf cache when ldconfig is available
if [[ -f %{_sbindir}/ldconfig ]]; then
    %{_sbindir}/ldconfig
fi

#---------------------------------------------------
%post perf
# Do this in every .spec file because they may only install a subset.
# We never know the order rpm is going to update AT's packages.
# So we only need to update the ldconf cache when ldconfig is available
if [[ -f %{_sbindir}/ldconfig ]]; then
    %{_sbindir}/ldconfig
fi

#---------------------------------------------------
%post mcore-libs
# Do this in every .spec file because they may only install a subset.
# We never know the order rpm is going to update AT's packages.
# So we only need to update the ldconf cache when ldconfig is available
if [[ -f %{_sbindir}/ldconfig ]]; then
    %{_sbindir}/ldconfig
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


####################################################
%preun devel
# Update the info directory entries
if [ "$1" = 0 ]; then
    for INFO in $(ls %{_infodir}/*.info.gz); do
        install-info --delete ${INFO} %{_infodir}/dir > /dev/null 2>&1 || :
    done
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

#---------------------------------------------------
%postun devel
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


####################################################
%files runtime -f %{at_work}/runtime.list
%defattr(-,root,root)
# Script for creating a wrapper ld for using the system
# libhugetlbfs/ld.hugetlbfs linker
%{_scriptdir}/createldhuge-1.0.sh
#Script for restoring the original Advance Toolchain ld.
%{_scriptdir}/restoreld.sh
# Config script for XLC/XLF
%{_scriptdir}/at-create-ibmcmp-cfg.sh

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
%files selinux
