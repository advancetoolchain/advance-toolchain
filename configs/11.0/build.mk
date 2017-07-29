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
# Generic build support options
# =============================
# Most of these options are self explanatory, Some highlights on obscure ones
# - BUILD_ARCH must contain the target toolchain arch (ppc64/ppc32)
# - BUILD_LOAD_ARCH tell us the CPU base to use for loader compatibility (GLIBC).
# - BUILD_BASE_ARCH tell us the CPU base to use for base code generation (GCC).
# - BUILD_OPTIMIZATION tells which is the default base optimization level (GCC).
# - BUILD_WITH_LONGDOUBLE tells us to build with support for longdoubles.
# - BUILD_WITH_DFP_STANDALONE tells us to build with libdfp as standalone library.
# - BUILD_RPM_PACKAGER tells us the name / email of packager for this release.
# - BUILD_RPMS must be set to "granular" or "monolithic" to indicate the kind of
#   rpms to be generated by the build script. See the documentation notes.

# When running on ppc64 (only), BUILD_ARCH defaults to ppc64.
# For all other host architectures, it defaults to ppc64le.
ifeq ($(HOST_ARCH),ppc64)
    BUILD_ARCH ?= ppc64
endif
BUILD_ARCH ?= ppc64le

# When building for ppc64le, the CPU base is power8.
# In the rest, it defaults to power7.
ifeq ($(BUILD_ARCH),ppc64le)
    BUILD_LOAD_ARCH ?= power8
    BUILD_BASE_ARCH ?= power8
endif
BUILD_LOAD_ARCH ?= power7
BUILD_BASE_ARCH ?= power7

BUILD_OPTIMIZATION := power8
BUILD_WITH_LONGDOUBLE := yes
BUILD_WITH_DFP_STANDALONE := yes
BUILD_RPM_PACKAGER :=
BUILD_RPM_VENDOR :=
BUILD_RPMS := monolithic
BUILD_GCC_LANGUAGES := c,c++,fortran,go

# List supported CPUs to build for active, compat and embed
# =========================================================
# - List of valid CPUs for active and compat:
#   * power4, power5, power5+, power6, power6x and power7

# CPU base on ppc64le is power8.
# Otherwise, CPU base is power7.
ifeq ($(BUILD_ARCH),ppc64le)
    BUILD_ACTIVE_MULTILIBS := power9
else
    BUILD_ACTIVE_MULTILIBS := power8 power9
endif

# Download options
# ================
# Should be either 'yes' or 'no'. Mostly self explanatory options.
# - BUILD_GET_SOURCES tell us to force grab sources
# - BUILD_GET_MPS tell us to grab patches from mailing lists
# - BUILD_GET_ADDONS tell us to grab related package addons
# - BUILD_EXCLUSIVE_CROSS tell us that the build is *exclusively* cross
# - BUILD_DEFAULT_RETRIES tell the default number of retries when fetching sources
BUILD_GET_SOURCES := yes
BUILD_GET_MPS := yes
BUILD_GET_ADDONS := yes
BUILD_EXCLUSIVE_CROSS := no
BUILD_DEFAULT_RETRIES := 5

# Miscellaneous
# =============
# Should be either 'yes' or 'no'. Mostly self explanatory options.
# - BUILD_ENVIRONMENT_MODULES: create and package an environment modules file
BUILD_ENVIRONMENT_MODULES := yes
