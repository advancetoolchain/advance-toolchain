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
$(eval $(call set_provides,zlib_1,multi,cross_yes))

# List of dependencies in order to build the tuned libraries for 32 or
# 64 bits.
zlib_tuned-32-deps := $(RCPTS)/gcc_3.rcpt \
                      $(RCPTS)/rsync_zlib.rcpt \
                      $(glibc_tuned-32-archdeps)
zlib_tuned-64-deps := $(RCPTS)/gcc_3.rcpt \
                      $(RCPTS)/rsync_zlib.rcpt \
                      $(glibc_tuned-64-archdeps)
# Enable tuned targets
$(eval $(call provide_tuneds,zlib))

zlib_1: $(RCPTS)/zlib_1.rcpt

zlib_tuned: $(RCPTS)/zlib_tuned.rcpt

$(RCPTS)/zlib_1.rcpt: $(zlib_1-archdeps)
	@touch $@

$(RCPTS)/zlib_1-32.a.rcpt: $(patsubst %,$(RCPTS)/%.rcpt,gcc_3 rsync_zlib)
	@touch $@

$(RCPTS)/zlib_1-64.a.rcpt: $(patsubst %,$(RCPTS)/%.rcpt,gcc_3 rsync_zlib)
	@touch $@

$(RCPTS)/zlib_tuned.rcpt: $(zlib_tuned-archdeps)
	@touch $@
