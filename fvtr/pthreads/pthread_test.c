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
   Built with:
   export PATH=/opt/at14.0/bin:$PATH
   gcc -mcpu=power8 -mtune=power8 -m64 -g -lpthread -o pthread_test pthread_test.c
*/

#include <errno.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>


static pthread_mutex_t m;
static pthread_barrier_t b;


static void *
tf (void *arg)
{
  int e = pthread_mutex_unlock (&m);
  if (e == 0)
    {
      puts ("child: 1st mutex_unlock succeeded");
      exit (1);
    }
  else if (e != EPERM)
    {
      puts ("child: 1st mutex_unlock error != EPERM");
      exit (1);
    }

  e = pthread_mutex_trylock (&m);
  if (e == 0)
    {
      puts ("child: 1st trylock suceeded");
      exit (1);
    }
  if (e != EBUSY)
    {
      puts ("child: 1st trylock didn't return EBUSY");
      exit (1);
    }

  e = pthread_barrier_wait (&b);
  if (e != 0 && e != PTHREAD_BARRIER_SERIAL_THREAD)
    {
      puts ("child: 1st barrier_wait failed");
      exit (1);
    }

  e = pthread_barrier_wait (&b);
  if (e != 0 && e != PTHREAD_BARRIER_SERIAL_THREAD)
    {
      puts ("child: 2nd barrier_wait failed");
      exit (1);
    }

  e = pthread_mutex_unlock (&m);
  if (e == 0)
    {
      puts ("child: 2nd mutex_unlock succeeded");
      exit (1);
    }
  else if (e != EPERM)
    {
      puts ("child: 2nd mutex_unlock error != EPERM");
      exit (1);
    }

  if (pthread_mutex_trylock (&m) != 0)
    {
      puts ("child: 2nd trylock failed");
      exit (1);
    }

  if (pthread_mutex_unlock (&m) != 0)
    {
      puts ("child: 3rd mutex_unlock failed");
      exit (1);
    }

  return NULL;
}


int
main (void)
{
  pthread_mutexattr_t a;
  int e;

  if (pthread_mutexattr_init (&a) != 0)
    {
      puts ("mutexattr_init failed");
      return 1;
    }

  if (pthread_mutexattr_settype (&a, PTHREAD_MUTEX_ERRORCHECK) != 0)
    {
      puts ("mutexattr_settype failed");
      return 1;
    }


  e = pthread_mutex_init (&m, &a);
  if (e != 0)
    {
      puts ("mutex_init failed");
      return 1;
    }

  if (pthread_barrier_init (&b, NULL, 2) != 0)
    {
      puts ("barrier_init failed");
      return 1;
    }

  e = pthread_mutex_unlock (&m);
  if (e == 0)
    {
      puts ("1st mutex_unlock succeeded");
      return 1;
    }
  else if (e != EPERM)
    {
      puts ("1st mutex_unlock error != EPERM");
      return 1;
    }

  if (pthread_mutex_lock (&m) != 0)
    {
      puts ("mutex_lock failed");
      return 1;
    }

  e = pthread_mutex_lock (&m);
  if (e == 0)
    {
      puts ("2nd mutex_lock succeeded");
      return 1;
    }
  else if (e != EDEADLK)
    {
      puts ("2nd mutex_lock error != EDEADLK");
      return 1;
    }

  pthread_t th;
  if (pthread_create (&th, NULL, tf, NULL) != 0)
    {
      puts ("create failed");
      return 1;
    }

  e = pthread_barrier_wait (&b);
  if (e != 0 && e != PTHREAD_BARRIER_SERIAL_THREAD)
    {
      puts ("1st barrier_wait failed");
      return 1;
    }

  if (pthread_mutex_unlock (&m) != 0)
    {
      puts ("2nd mutex_unlock failed");
      return 1;
    }

  e = pthread_mutex_unlock (&m);
  if (e == 0)
    {
      puts ("3rd mutex_unlock succeeded");
      return 1;
    }
  else if (e != EPERM)
    {
      puts ("3rd mutex_unlock error != EPERM");
      return 1;
    }

  e = pthread_barrier_wait (&b);
  if (e != 0 && e != PTHREAD_BARRIER_SERIAL_THREAD)
    {
      puts ("2nd barrier_wait failed");
      return 1;
    }

  if (pthread_join (th, NULL) != 0)
    {
      puts ("join failed");
      return 1;
    }

  if (pthread_mutex_destroy (&m) != 0)
    {
      puts ("mutex_destroy failed");
      return 1;
    }

  if (pthread_barrier_destroy (&b) != 0)
    {
      puts ("barrier_destroy failed");
      return 1;
    }

  if (pthread_mutexattr_destroy (&a) != 0)
    {
      puts ("mutexattr_destroy failed");
      return 1;
    }

  return 0;
}
