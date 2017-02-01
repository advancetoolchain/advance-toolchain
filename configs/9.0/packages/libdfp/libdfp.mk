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
$(eval $(call set_provides,libdfp_1,multi,cross_yes))

# Dependencies for the un-tuned libraries
ifeq ($(CROSS_BUILD),no)
	libdfp-32-deps := $(RCPTS)/gcc_3.rcpt \
	                  $(RCPTS)/glibc_2-32.b.rcpt \
	                  $(RCPTS)/rsync_libdfp.rcpt
	libdfp-64-deps := $(RCPTS)/gcc_3.rcpt \
	                  $(RCPTS)/glibc_2-64.b.rcpt \
	                  $(RCPTS)/rsync_libdfp.rcpt
else
	libdfp-32-deps := $(RCPTS)/gcc_4.rcpt \
	                  $(RCPTS)/rsync_libdfp.rcpt
	libdfp-64-deps := $(RCPTS)/gcc_4.rcpt \
	                  $(RCPTS)/rsync_libdfp.rcpt
endif

# List of dependencies in order to build the tuned libraries for 32 or
# 64 bits.
libdfp_tuned-32-deps := $(RCPTS)/rsync_libdfp.rcpt \
                        $(RCPTS)/gcc_3.rcpt \
                        $(RCPTS)/glibc_2-32.b.rcpt \
                        $(glibc_tuned-32-archdeps)
libdfp_tuned-64-deps := $(RCPTS)/rsync_libdfp.rcpt \
                        $(RCPTS)/gcc_3.rcpt \
                        $(RCPTS)/glibc_2-64.b.rcpt \
                        $(glibc_tuned-64-archdeps)
# Enable tuned targets
$(eval $(call provide_tuneds,libdfp))

libdfp_1: $(RCPTS)/libdfp_1.rcpt

libdfp_tuned: $(RCPTS)/libdfp_tuned.rcpt

$(RCPTS)/libdfp_1.rcpt: $(libdfp_1-archdeps)
	@touch $@

$(RCPTS)/libdfp_1-32.a.rcpt: $(libdfp-32-deps)
	@touch $@

$(RCPTS)/libdfp_1-64.a.rcpt: $(libdfp-64-deps)
	@touch $@

$(RCPTS)/libdfp_tuned.rcpt: $(libdfp_tuned-archdeps)
	@touch $@
