/* Copyright 2017 IBM Corporation
*
*  Licensed under the Apache License, Version 2.0 (the "License");
*  you may not use this file except in compliance with the License.
*  You may obtain a copy of the License at
*
*     http://www.apache.org/licenses/LICENSE-2.0
*
*  Unless required by applicable law or agreed to in writing, software
*  distributed under the License is distributed on an "AS IS" BASIS,
*  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
*  See the License for the specific language governing permissions and
*  limitations under the License.
*/

/* Basic test to override the default malloc and free implementations by the
   ones provided by TBB.  */

#include <stdlib.h>
#include <err.h>

int main()
{
  /* During the link phase we override malloc and free.  */
  char *block = (char *) malloc(4096);
  if (!block) {
    err(1, "Can't allocate memory.");
  }

  free(block);

  return 0;
};
