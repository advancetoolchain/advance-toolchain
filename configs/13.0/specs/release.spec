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

# The product is called 'ibm-power-advance-toolchain' in SCC.
%define         product ibm-power-advance-toolchain

# Per convention the %%package name will be used a stem for the -release
# package.
%define         package advance-toolchain-%{at_major}

# Decide: The products version and release often follows the release package.
# In this case use the -release packages %%{version} and %%{release}. But
# it is possible to maintain different v-r for product and -release package.
# In this case the products v-r would be defined here.
%define         productversion %{at_major_version}
%define         productrelease %{at_revision_number}

# The date when this Product goes out of support. A missing value indicates
# that there will be no EOL, while an empty/invalid value indicates that
# there will be an EOL date, but it's not yet known.
%define         productendoflife __AT_END_OF_LIFE__
%define         productendoflife_pcescaped __AT_END_OF_LIFE_ESCAPED__

%define         producturlbugtracker https://github.com/advancetoolchain/advance-toolchain/issues/
%define         producturlbugtracker_pcescaped https%3A%2F%2Fgithub.com%2Fadvancetoolchain%2Fadvance%2Dtoolchain%2Fissues%2F

# ----------------------------------------------------------------------

Name:           %{package}-release
Summary:        Advance Toolchain
Version:        %{productversion}
Release:        %{productrelease}
License:        GPL, LGPL
Group:          Development/Libraries
Vendor:         __RPM_VENDOR__

Provides:       %name-%version
# ======================================================================
# Product indicator provides (mandatory and important):
Provides:       product() = %{product}
Provides:       product(%{product}) = %{productversion}-%{productrelease}
# Additional product data exposed in the -release package:
Provides:       product-endoflife() = %{productendoflife_pcescaped}
Provides:       product-url(bugtracker) = %{producturlbugtracker_pcescaped}
# ----------------------------------------------------------------------

Requires:       product(SUSE_SLE) >= __DISTRO_VERSION__
Suggests:       %{package}-runtime
AutoReqProv:    no

%description
The IBM Advance Toolchain is a self-contained toolchain that provides
open-source compilers, runtime libraries, and development tools to take
advantage of the latest IBM Power hardware features on Linux.

%prep

%build

%install

mkdir -p $RPM_BUILD_ROOT/etc/products.d
cat >$RPM_BUILD_ROOT/etc/products.d/%{product}.prod << EOF
<?xml version="1.0" encoding="UTF-8"?>
<product schemeversion="0">
  <vendor>__RPM_VENDOR__</vendor>
  <name>%{product}</name>
  <version>%{productversion}</version>
  <baseversion>__DISTRO_VERSION__</baseversion>
  <patchlevel>0</patchlevel>
  <predecessor>sle-sdk</predecessor>
  <release>%{productrelease}</release>
  <endoflife>%{productendoflife}</endoflife>
  <arch>__TARGET_ARCH__</arch>
  <summary>Advance Toolchain</summary>
  <description>
&lt;p&gt;The IBM Advance Toolchain is a self-contained toolchain that provides 
open-source compilers, runtime libraries, and development tools to take 
advantage of the latest IBM Power hardware features on Linux.&lt;/p&gt;
  </description>
  <urls>
    <url name="bugtracker">%{producturlbugtracker}</url>
  </urls>
  <buildconfig>
    <producttheme>SLES</producttheme>
  </buildconfig>
  <installconfig>
    <defaultlang>en_US</defaultlang>
    <releasepackage name="%{name}" flag="EQ" version="%{version}" release="%{release}"/>
    <distribution>SUSE_SLE</distribution>
  </installconfig>
  <runtimeconfig/>
  <productdependency relationship="requires" name="SUSE_SLE" baseversion="__DISTRO_VERSION__" patchlevel="0" flag="GE"/>
</product>

EOF


%files
%defattr(644,root,root,755)
%dir /etc/products.d
/etc/products.d/*

%changelog

