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

#include <stdio.h>
#define N 10

int x;
static double a[N];
void init_x() { 
  x = 12;
}

int main(void)
{
  int i=0;
  double *p;

  x = 0;
  p = &a[4];
  init_x();

  for (i=0; i<N; i++) {
    a[i] = (double)(i*x);
    x += i;
  }
  printf("Results:  x=%d a[7]=%6.2f p=%p\n", x, a[7], p);

  return 0;
}

