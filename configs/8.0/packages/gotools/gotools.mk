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
# Go tools are available only for native AT-8.0 builds. Cross AT-8.0 builds do
# not support go tools, yet.
#
# Native go tools could be built and provided on cross AT-8.0 builds, which
# could then invoke the cross powerpc64[le]-linux-gnu-gccgo compiler.
#
# However, as of March 2015 this kind of cross-compilation is not supported by
# the community, thus cross AT-8.0 builds do not include any go tools.
#
$(eval $(call set_provides,gotools_1,single,cross_no))

gotools: $(RCPTS)/gotools_1.rcpt

$(RCPTS)/gotools_1.rcpt: $(gotools_1-archdeps)
	@touch $@

$(RCPTS)/gotools_1.a.rcpt: $(patsubst %,$(RCPTS)/%.rcpt,gcc_4 rsync_gotools)
	@touch $@

