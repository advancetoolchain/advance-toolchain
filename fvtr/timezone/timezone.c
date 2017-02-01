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

/* Print the timezone in the same format of `date '+%z'. */

#include <time.h>
#include <stdlib.h>
#include <stdio.h>
#include <errno.h>

extern char * tzname[2];

int
main () {
  time_t now;
  struct tm * lt;
  char tz[10];

  now = time(NULL);
  if (now == -1) {
    perror ("Failed to read time");
    exit (1);
  }

  lt = localtime(&now);
  if (lt == 0) {
    perror ("Failed to get localtime");
    exit (1);
  }

  if (strftime(tz, sizeof(tz), "%z", lt) == 0) {
    perror ("Failed to get timezone");
    exit (1);
  }

  printf("%s\n", tz);

  return 0;
}
