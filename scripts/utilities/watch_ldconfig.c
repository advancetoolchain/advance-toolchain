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

/*
 * This program monitors the /etc/ld.so.cache to identify when the system's
 * ldconfig is executed.
 * When /etc/ld.so.cache changes AT's ldconfig is called to also update the
 * ld.so.cache from AT.
 */
#include <stdlib.h>
#include <sys/inotify.h>
#include <errno.h>
#include <string.h>
#include <signal.h>
#include <stdio.h>

#define BUF_LEN  ( 1024 * (sizeof (struct inotify_event)) )

#define RUN_AT_LDCONFIG(PATH)  AT_LDCONFIG( PATH )
#define AT_LDCONFIG(PATH) system( #PATH )

// inotify file descriptor and watch.
volatile int fd, watch;

void clean(int signum)
{
  (void) inotify_rm_watch(fd, watch);
  (void) close(fd);
}

int
main(int argc, char **argv)
{
  int length;
  char buffer[BUF_LEN];
  char command[50];

  // Handle SIGTERM
  struct sigaction action;
  memset(&action, 0, sizeof(struct sigaction));
  action.sa_handler = clean;
  sigaction(SIGTERM, &action, NULL);

  fd = inotify_init();
  if (fd < 0)
    perror("Error: Not able to start inotify!");

  while (1)
  {
    // Add a watch to monitor /etc/ld.so.cache.
    watch = inotify_add_watch(fd, "/etc/ld.so.cache", IN_MODIFY);

    // Wait for an event.
    length = read(fd, buffer, BUF_LEN);
    if (length < 0)
      perror("Error: Read error.");

    // Run AT's ldconfig.
#ifndef AT_LDCONFIG_PATH
#  error "AT_LDCONFIG_PATH is not defined!"
#endif
    RUN_AT_LDCONFIG(AT_LDCONFIG_PATH);
  }


  (void) inotify_rm_watch(fd, watch);
  (void) close(fd);

  return 0;
}
