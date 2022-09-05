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
#
$(eval $(call set_provides,glibc_1,multi,cross_yes))
$(eval $(call set_provides,glibc_2,multi,cross_no))
ifeq ($(BUILD_IGNORE_COMPAT),no)
    $(eval $(call set_provides,glibc_compat,multi,cross_no))
endif

# List of dependencies in order to build the tuned libraries for 32 or
# 64 bits.
glibc_tuned-32-deps := $(RCPTS)/gcc_3.rcpt \
                       $(RCPTS)/rsync_glibc.rcpt
glibc_tuned-64-deps := $(RCPTS)/gcc_3.rcpt \
                       $(RCPTS)/rsync_glibc.rcpt
# Enable tuned targets
$(eval $(call provide_tuneds,glibc))

glibc_1: $(RCPTS)/glibc_1.rcpt

glibc_2: $(RCPTS)/glibc_2.rcpt

glibc_compat: $(RCPTS)/glibc_compat.rcpt

glibc_tuned: $(RCPTS)/glibc_tuned.rcpt

$(RCPTS)/glibc_1.rcpt: $(glibc_1-archdeps)
	@touch $@

$(RCPTS)/glibc_2.rcpt: $(glibc_2-archdeps)
	@touch $@

$(RCPTS)/glibc_compat.rcpt: $(glibc_compat-archdeps)
	@touch $@

$(RCPTS)/glibc_1-32.a.rcpt: $(RCPTS)/gcc_1.rcpt $(RCPTS)/rsync_glibc.rcpt
	@touch $@

$(RCPTS)/glibc_1-64.a.rcpt: $(RCPTS)/gcc_1.rcpt $(RCPTS)/rsync_glibc.rcpt
	@touch $@

$(RCPTS)/glibc_2-32.a.rcpt: $(RCPTS)/gcc_3.rcpt
	@touch $@

$(RCPTS)/glibc_2-64.a.rcpt: $(RCPTS)/gcc_3.rcpt
	@touch $@

$(RCPTS)/glibc_compat-32.a.rcpt: $(RCPTS)/gcc_3.rcpt
	@touch $@

$(RCPTS)/glibc_compat-64.a.rcpt: $(RCPTS)/gcc_3.rcpt
	@touch $@

$(RCPTS)/glibc_tuned.rcpt: $(glibc_tuned-archdeps)
	@touch $@
