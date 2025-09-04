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
$(eval $(call set_provides,openssl_1,multi,cross_yes))

# List of dependencies in order to build the tuned libraries for 32 or
# 64 bits.
openssl_tuned-32-deps := $(RCPTS)/gcc_4.rcpt \
                         $(RCPTS)/rsync_openssl.rcpt
openssl_tuned-64-deps := $(RCPTS)/gcc_4.rcpt \
                         $(RCPTS)/rsync_openssl.rcpt
# Enable tuned targets
$(eval $(call provide_tuneds,openssl))

openssl_1: $(RCPTS)/openssl_1.rcpt

openssl_tuned: $(RCPTS)/openssl_tuned.rcpt

$(RCPTS)/openssl_1.rcpt: $(openssl_1-archdeps)
	@touch $@

$(RCPTS)/openssl_1-32.a.rcpt: $(patsubst %,$(RCPTS)/%.rcpt,gcc_4 zlib_1 rsync_openssl)
	@touch $@

$(RCPTS)/openssl_1-64.a.rcpt: $(patsubst %,$(RCPTS)/%.rcpt,gcc_4 zlib_1 rsync_openssl)
	@touch $@

$(RCPTS)/openssl_tuned.rcpt: $(openssl_tuned-archdeps)
	@touch $@
