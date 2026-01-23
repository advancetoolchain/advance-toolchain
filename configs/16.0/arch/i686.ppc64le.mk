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
# Set default variables when host=i686 targeting ppc64le.

# Generate 64-bit binaries by default.
COMPILER := 64
# We only build for 64 bits on little endian, because its ABI doesn't support
# 32-bit mode.
BUILD_TARGET_ARCH64 := powerpc64le

include $(CONFIG)/arch/default.mk
HOST := $(HOST_ARCH)-pc-linux-gnu

DEFAULT_CPU := default64
HEADER_TARGET64 := ppc64le
TARGET := $(CTARGET_64)

CROSS_BUILD := yes
ENV_BUILD_ARCH := 32

# Change the default sysroot path in order to not conflict with other builds.
DEST_CROSS=$(strip $(shell $(call mkpath,$(AT_DEST)/$(BUILD_ARCH),no)))

# Don't build 32-bit libraries when targeting 64-bit only.
DISABLE_MULTILIB := yes
