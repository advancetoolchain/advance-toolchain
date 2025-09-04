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
$(eval $(call set_provides,paflib_1,multi,cross_yes))

paflib: $(RCPTS)/paflib_1.rcpt

#Add it to the target 3rdparty_libs
3rdparty_libs-reqs += $(RCPTS)/paflib_1.rcpt

$(RCPTS)/paflib_1.rcpt: $(paflib_1-archdeps)
	@touch $@

$(RCPTS)/paflib_1-32.a.rcpt: $(RCPTS)/gcc_4.rcpt $(RCPTS)/rsync_paflib.rcpt
	@touch $@

$(RCPTS)/paflib_1-64.a.rcpt: $(RCPTS)/gcc_4.rcpt $(RCPTS)/rsync_paflib.rcpt
	@touch $@
