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
import gdb
class HelloGdb(gdb.Command):

  def __init__ (self):
    super (HelloGdb, self).__init__("hello-gdb", gdb.COMMAND_USER)

  def invoke(self, arg, from_tty):
    print "Hello GDB from Python!"

HelloGdb()
