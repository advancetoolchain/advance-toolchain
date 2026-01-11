# Copyright 2020 IBM Corporation
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
# TODO Replace "<project_name>" for the actual project name. For example
# s/<project_name>/libfoo/g if you want to include libfoo on AT.

# This file will be automaticaly added to the makefiles. Thats why you can call
# set providers.
# TODO Adjust the parameters for your project:
#
# arg1: Package name. This name will be used for reciepes generation.
# arg2: XXX
# arg3: XXX
#
# For more information about this call see file XXX
$(eval $(call set_provides,<project_name>_1,multi,cross_yes))

<project_name>: $(RCPTS)/<project_name>_1.rcpt

# Add it to the target 3rdparty_libs.
3rdparty_libs-reqs += $(RCPTS)/<project_name>_1.rcpt

# TODO Add architecture depencencies. Leave the ones you need to support.
#$(RCPTS)/<project_name>_1.rcpt: $(RCPTS)/<project_name>_1-64.b.rcpt 
#	@touch $@


# TODO Add 32bit requisites. Here we have most common requisites it might be
#$(RCPTS)/<project_name>_1-32.a.rcpt: $(RCPTS)/gcc_4.rcpt $(RCPTS)/rsync_<project_name>.rcpt
#	@touch $@


# TODO Add 64bit requisites. Here we have most common requisites it might be
# necessarie to add or remove as you need.
#$(RCPTS)/<project_name>_1-64.a.rcpt: $(RCPTS)/gcc_4.rcpt $(RCPTS)/rsync_<project_name>.rcpt
#	@touch $@
