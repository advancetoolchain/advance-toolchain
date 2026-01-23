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
$(eval $(call set_provides,binutils_1,single,cross_yes))
$(eval $(call set_provides,binutils_2,single,cross_yes))

ifeq ($(CROSS_BUILD),no)
	binutils_2-req = $(RCPTS)/ldconfig_2.rcpt
else
	binutils_2-req = 
endif


binutils_1: $(RCPTS)/binutils_1.rcpt

binutils_2: $(RCPTS)/binutils_2.rcpt


$(RCPTS)/binutils_1.rcpt: $(binutils_1-archdeps)
	@touch $@

$(RCPTS)/binutils_2.rcpt: $(binutils_2-archdeps)
	@touch $@


$(RCPTS)/binutils_1.a.rcpt: $(RCPTS)/rsync_binutils.rcpt
	@touch $@

$(RCPTS)/binutils_2.a.rcpt: $(RCPTS)/glibc_2.rcpt $(RCPTS)/gcc_3.rcpt $(binutils_2-req)
	@touch $@

