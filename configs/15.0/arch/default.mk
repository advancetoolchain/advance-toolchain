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
# Default settings for all scenarios.
# Define at least BUILD_TARGET_ARCH* before including this file.

# Generate code with non-executable .plt and .got sections for powerpc-linux.
SECURE_PLT ?= secure-plt

# DEFAULT_CPU is used by gcc in order to set the default value of -m[32|64]
DEFAULT_CPU ?= default32

# Generate 32-bit binaries by default when not set.
# This is a legacy value.
COMPILER ?= 32

# We only build for Linux + glibc.
BUILD_TARGET_OSLIB ?= linux-gnu
CANONICALIZED_MACHINE := $(BUILD_TARGET_OSLIB)
CANONICALIZED_NAME_ID := $(CANONICALIZED_MACHINE)$(BUILD_TARGET_POSTFIX)

ifdef BUILD_TARGET_ARCH32
  # Name of the target used when installing headers.  It may be the name of the
  # directory or a prefix of the name.
  HEADER_TARGET ?= ppc
  CTARGET_32 := $(BUILD_TARGET_ARCH32)-$(CANONICALIZED_NAME_ID)
  TARGET32 := $(CTARGET_32)
endif

ifdef BUILD_TARGET_ARCH64
  # Name of the target used when installing headers.  It may be the name of the
  # directory or a prefix of the name.
  HEADER_TARGET64 ?= ppc64
  CTARGET_64 := $(BUILD_TARGET_ARCH64)-$(CANONICALIZED_NAME_ID)
  TARGET64 := $(CTARGET_64)
endif
