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
$(eval $(call set_provides,gdb_1,single,cross_yes))

gdb-deps :=
ifeq ($(CROSS_BUILD),no)
    gdb-deps := python_1 ldconfig_3
endif

gdb_1: $(RCPTS)/gdb_1.rcpt

$(RCPTS)/gdb_1.rcpt: $(gdb_1-archdeps)
	@touch $@

$(RCPTS)/gdb_1.a.rcpt: $(patsubst %,$(RCPTS)/%.rcpt,gcc_4 \
                                                    expat_1 \
                                                    rsync_gdb \
                                                    $(gdb-deps))
	@touch $@
