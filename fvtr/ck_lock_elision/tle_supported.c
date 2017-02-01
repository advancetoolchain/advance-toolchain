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
#include <stdlib.h>
#include <pthread.h>
#include <errno.h>

#include <sys/auxv.h>


/* glibc doesn't export this constant, but if set, it indicates the
   elided locks are used. It probably won't change, but it is the
   only way to verify if elision is actually being used. */
#define LE_ENABLED_BIT (256)

int
main ()
{
	/* Verify we've got HTM support */
	unsigned long int hwcap2 = getauxval (AT_HWCAP2);

	if (!hwcap2) {
		perror ("getauxval");
		return EXIT_FAILURE;
	}

	if (!(hwcap2 & PPC_FEATURE2_HAS_HTM))
		return ENOSYS;

	pthread_mutex_t lock = PTHREAD_MUTEX_INITIALIZER;
	/* By default, a lock is never an elidable lock, but if
	   configured with elided locks, it will be "promoted" after
	   the first lock */
	if (pthread_mutex_lock (&lock)) {
		perror ("pthread_mutex_lock");
		return EXIT_FAILURE;
	}
	if( lock.__data.__kind & LE_ENABLED_BIT ) {
		return EXIT_SUCCESS;
	}
	fprintf (stderr, "kind is %d\n", lock.__data.__kind);
	return EXIT_FAILURE;
}
