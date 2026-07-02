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
%package runtime
Summary: Advance Toolchain
Requires: __AT_RUNTIME_REQ__
Group: Development/Libraries
AutoReqProv: no
Requires: __RUNTIME_DEPENDENT_PACKAGES__

%description runtime
The IBM Advance Toolchain is a self-contained toolchain that provides
open-source compilers, runtime libraries, and development tools to take
advantage of the latest IBM Power hardware features on Linux.
This package contains the runtime libraries to run programs built with the
Advance Toolchain.

####################################################
%package runtime-compat
Summary: Advance Toolchain
Requires: __AT_RUNTIME_COMPAT_REQ__Conflicts: advance-toolchain-%{at_major}-runtime
Group: Development/Libraries
AutoReqProv: no
Requires: __RUNCOMPAT_DEPENDENT_PACKAGES__

%description runtime-compat
The IBM Advance Toolchain is a self-contained toolchain that provides
open-source compilers, runtime libraries, and development tools to take
advantage of the latest IBM Power hardware features on Linux.


####################################################
%package devel
Summary: Advance Toolchain
Requires: advance-toolchain-%{at_major}-runtime = %{at_major_version}-%{at_revision_number}, __AT_DEVEL_REQ__
Group: Development/Libraries
AutoReqProv: no
Provides: advance-toolchain-devel = %{at_major_version}-%{at_revision_number}
Requires: __DEVEL_DEPENDENT_PACKAGES__

%description devel
The IBM Advance Toolchain is a self-contained toolchain that provides
open-source compilers, runtime libraries, and development tools to take
advantage of the latest IBM Power hardware features on Linux.
This package provides the packages necessary to build applications that use the
features provided by the Advance Toolchain.


####################################################
%package mcore-libs
Summary: Advance Toolchain
Requires: advance-toolchain-%{at_major}-runtime = %{at_major_version}-%{at_revision_number}, __AT_MCORE_LIBS_REQ__
Group: Development/Libraries
AutoReqProv: no
Requires: __MCORE_DEPENDENT_PACKAGES__

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
Requires: advance-toolchain-%{at_major}-devel = %{at_major_version}-%{at_revision_number}, __AT_PERF_REQ__
Group: Development/Libraries
AutoReqProv: no
Requires: __PERF_DEPENDENT_PACKAGES__
Provides: advance-toolchain-perf = %{at_major_version}-%{at_revision_number}

%description perf
The IBM Advance Toolchain is a self-contained toolchain that provides
open-source compilers, runtime libraries, and development tools to take
advantage of the latest IBM Power hardware features on Linux.
This 'perf' package contains the performance library install targets
for Valgrind.


####################################################
%files runtime

#---------------------------------------------------
%files runtime-compat

#---------------------------------------------------
%files devel

#---------------------------------------------------
%files perf

#---------------------------------------------------
%files mcore-libs







Requires: __DEPENDENT_PACKAGES__
