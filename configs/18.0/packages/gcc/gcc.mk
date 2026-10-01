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
#
#
$(eval $(call set_provides,gcc_1,single,cross_yes))
$(eval $(call set_provides,gcc_3,single,cross_yes))
$(eval $(call set_provides,gcc_4,single,cross_yes))

# List of dependencies in order to build the tuned libraries.
gcc_tuned-deps := $(RCPTS)/gcc_4.rcpt
# Enable tuned targets
$(eval $(call provide_tuneds,gcc))

# gcc_4 doesn't require mpc_2 on cross.
ifeq ($(CROSS_BUILD),no)
    gcc_4-reqs += $(RCPTS)/mpc_2.rcpt
endif


gcc_1: $(RCPTS)/gcc_1.rcpt

gcc_3: $(RCPTS)/gcc_3.rcpt

gcc_4: $(RCPTS)/gcc_4.rcpt

gcc_tuned: $(RCPTS)/gcc_tuned.rcpt

$(RCPTS)/gcc_1.rcpt: $(gcc_1-archdeps)
	@touch $@

$(RCPTS)/gcc_3.rcpt: $(gcc_3-archdeps)
	@touch $@

$(RCPTS)/gcc_4.rcpt: $(gcc_4-archdeps)
	@touch $@


$(RCPTS)/gcc_1.a.rcpt: $(RCPTS)/binutils_1.rcpt \
                       $(RCPTS)/mpc_1.rcpt \
                       $(RCPTS)/kernel_h.rcpt \
                       $(RCPTS)/rsync_gcc.rcpt
	@touch $@

$(RCPTS)/gcc_3.a.rcpt: $(RCPTS)/ldconfig_1.rcpt \
                       $(RCPTS)/glibc_1.rcpt
	@touch $@

$(RCPTS)/gcc_4.a.rcpt: $(RCPTS)/binutils_2.rcpt \
                       $(RCPTS)/gcc_3.rcpt \
                       $(gcc_4-reqs)
	@touch $@

$(RCPTS)/gcc_tuned.rcpt: $(gcc_tuned-archdeps)
	@touch $@
