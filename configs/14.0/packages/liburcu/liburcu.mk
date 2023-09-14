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
$(eval $(call set_provides,liburcu_1,multi,cross_yes))

liburcu: $(RCPTS)/liburcu_1.rcpt

# Add it to the target 3rdparty_libs
3rdparty_libs-reqs += $(RCPTS)/liburcu_1.rcpt

$(RCPTS)/liburcu_1.rcpt: $(liburcu_1-archdeps)
	@touch $@

$(RCPTS)/liburcu_1-32.a.rcpt: $(patsubst %,$(RCPTS)/%.rcpt,gcc_4 rsync_liburcu)
	@touch $@

$(RCPTS)/liburcu_1-64.a.rcpt: $(patsubst %,$(RCPTS)/%.rcpt,gcc_4 rsync_liburcu)
	@touch $@
