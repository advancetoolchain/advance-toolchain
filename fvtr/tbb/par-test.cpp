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

/* The goal of this test is to ensure that none of the headers in
   tbb/internal are missing, and the test uses the parallel_for function
   to test if the main libraries are available.  */

#include <stdlib.h>
#include <err.h>
/* These are public headers which uses the internal ones.  */
#include <tbb/tbb.h>
#include <tbb/flow_graph.h>
#include <tbb/parallel_while.h>
#include <tbb/tbbmalloc_proxy.h>
#include <tbb/tbb_config.h>
#include <tbb/tbb_machine.h>
#include <tbb/tbb_profiling.h>
#include <tbb/blocked_range.h>
#include <tbb/parallel_for.h>
#include <tbb/task_scheduler_init.h>
#include <tbb/internal/_aggregator_impl.h>
/* These are not included in the public ones.  */
#define __TBB_tbb_windef_H
#define _MT
#include <tbb/internal/_tbb_windef.h>

/* Struct that does the computation.  */
struct
execute
{
  execute():size(1000){}
  void operator()() const
  {
    for(int i = 0; i <= 10000000; i++)
      i = i * i;
  }
  int size;
};

/* Struct that is passed to the parallel_for.  */
struct
trigger
{
  trigger(execute ex): job(ex) {}
  void operator()(const tbb::blocked_range<size_t>& r) const
  {
    for(int i = 0; i <= 1000; i++)
      job();
  }

  execute job;
};

int main()
{
  /* During the link phase we override malloc and free.  */
  char *block = (char *) malloc(4096);
  if (!block) {
    err(1, "Can't allocate memory.");
  }

  free(block);

  /* Tests the function using 18 threads.  */
  tbb::task_scheduler_init init(18);
  execute job;
  struct trigger trig(job);
  tbb::parallel_for(tbb::blocked_range<size_t>(0,1000),trig);

  return 0;
};
