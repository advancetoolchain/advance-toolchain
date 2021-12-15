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
# Golang is available only for native pcc64le builds.

$(eval $(call set_provides,golang_1,single,cross_no,skip_ppc64))

golang_1: $(RCPTS)/golang_1.rcpt

$(RCPTS)/golang_1.rcpt: $(golang_1-archdeps)
	@touch $@

$(RCPTS)/golang_1.a.rcpt: $(patsubst %,$(RCPTS)/%.rcpt, rsync_golang)
	@touch $@
