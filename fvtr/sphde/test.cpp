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

#include <sphde/sassim.h>

int main ()
{
  int rc;

  rc = SASJoinRegion();
  if (!rc)
    {
      char *block;

      // allocation a block of SPHDE data ...
      block = (char*) SASBlockAlloc (4096);
     block[0] = 'a';

      SASCleanUp();
      return 0;
    }
  return 1;
}
