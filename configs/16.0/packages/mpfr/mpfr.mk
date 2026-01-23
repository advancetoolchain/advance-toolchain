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
# In a native build, the first stage of this packages is created using the
# system toolchain.
# As soon as the new toolchain is fully featured, we rebuild this package.
# In a cross compiler, this package is built for the host architecture,
# using the system toolchain, which is already fully featured.  So, we don't
# need to rebuild it.
#
$(eval $(call set_provides,mpfr_1,single,cross_yes))
$(eval $(call set_provides,mpfr_2,single,cross_no))


mpfr_1: $(RCPTS)/mpfr_1.rcpt

mpfr_2: $(RCPTS)/mpfr_2.rcpt


# Build it using the system toolchain
$(RCPTS)/mpfr_1.rcpt: $(mpfr_1-archdeps)
	@touch $@

# Rebuild it using the new fully featured toolchain
$(RCPTS)/mpfr_2.rcpt: $(mpfr_2-archdeps)
	@touch $@


$(RCPTS)/mpfr_1.a.rcpt: $(RCPTS)/gmp_1.rcpt $(RCPTS)/rsync_mpfr.rcpt
	@touch $@

$(RCPTS)/mpfr_2.a.rcpt: $(RCPTS)/gmp_2.rcpt
	@touch $@
