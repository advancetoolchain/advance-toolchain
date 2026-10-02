# Copyright 2022 IBM Corporation
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
$(eval $(call set_provides,python_1,single,cross_no))

python_tuned-deps := $(RCPTS)/python_1.rcpt

# Enable tuned targets
$(eval $(call provide_tuneds,python))

python_1: $(RCPTS)/python_1.rcpt

$(RCPTS)/python_1.rcpt: $(python_1-archdeps)
	@touch $@

$(RCPTS)/python_1.a.rcpt: $(patsubst %,$(RCPTS)/%.rcpt,gcc_4 expat_1 openssl_1-64.b ldconfig_2 rsync_python)
	@touch $@

$(RCPTS)/python_tuned.rcpt: $(python_tuned-archdeps)
	@touch $@
