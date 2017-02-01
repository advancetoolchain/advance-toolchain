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

#include <auxv/auxv.h>
#include <auxv/hwcap.h>
#include <assert.h>
#include <unistd.h>
#include <stdio.h>
#include <errno.h>
#include <link.h>

int main()
{
  ElfW(auxv_t) *at_ptr = NULL;
  unsigned long int hwcap_mask;
  char * platform = NULL;

  if (prefetch_auxv ())
    {
      printf("prefetch_auxv () failed with errno %d.\\n", errno);
      return -1;
    }

  hwcap_mask = (unsigned long int) query_auxv (AT_HWCAP);

  printf("HWCAP=0x%0*lx\\n",2 * (int) sizeof(unsigned long int), hwcap_mask);

#ifdef __powerpc__
  if (hwcap_mask & PPC_FEATURE_64)
      printf("  64-bit\\n");

  if (hwcap_mask & PPC_FEATURE_32)
      printf("  32-bit\\n");
#endif

  platform = (char*) query_auxv (AT_PLATFORM);

  if (platform)
    printf("PLATFORM=%s\\n", platform);
  else
    printf("AT_PLATFORM not supported\\n");

  assert (query_auxv (AT_PAGESZ) == getpagesize ());

  at_ptr = get_auxv ();
  printf("get_auxv() = %p\\n", at_ptr);

  return 0;
}
