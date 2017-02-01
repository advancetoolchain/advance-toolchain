#!/bin/bash
#
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
#
# File: pkg_build_filelists.sh
#
# Description
#   Check which kind of rpm should be generated: monolithic or granular
#   - Monolithic: only four main packages + compatibility runtime
#   - Granular: each package has its own original package and they are grouped
#     by meta-packages, or package groups into the four main packages +
#     compatibility runtime.
#
# Parameters
# - none
#

# Load required external functions
source "${utilities}/pkg_build_granular.sh"
source "${utilities}/pkg_build_monolithic.sh"

# Decide which kind of build to perform by the definition present on
# rpm_build_type (granular|monolithic).
# We have used since the beginning the monolithic build type, but
# there may be chances to implement the former one sometime in the
# future...
if [[ "${rpm_build_type}" == "granular" ]]; then
	echo "Doing granular packaging..."
	granular_filelists
else
	echo "Doing monolithic packaging..."
	monolithic_filelists
fi
