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
$(eval $(call set_provides,libsphde_1,multi,cross_yes))

libsphde: $(RCPTS)/libsphde_1.rcpt

# Add it to the target 3rdparty_libs
3rdparty_libs-reqs += $(RCPTS)/libsphde_1.rcpt

ifeq ($(CROSS_BUILD),no)
        libsphde-deps-32 := glibc_2-32.b
        libsphde-deps-64 := glibc_2-64.b
else
        # The cross compiler don't build glibc_2.  So, libsphde has to depend
        # on gcc_4.
        libsphde-deps-32 := gcc_4
        libsphde-deps-64 := gcc_4
endif

$(RCPTS)/libsphde_1.rcpt: $(libsphde_1-archdeps)
	@touch $@

$(RCPTS)/libsphde_1-32.a.rcpt: $(patsubst %,$(RCPTS)/%.rcpt,\
                                          $(libsphde-deps-32) \
                                          rsync_libsphde)
	@touch $@

$(RCPTS)/libsphde_1-64.a.rcpt: $(patsubst %,$(RCPTS)/%.rcpt,\
                                          $(libsphde-deps-64) \
                                          rsync_libsphde)
	@touch $@
