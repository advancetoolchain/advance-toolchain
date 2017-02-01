#include <stdlib.h>

int
main (void)
{
  if (__builtin_cpu_supports ("ppc32") == 0
      && __builtin_cpu_supports ("ppc64") == 0)
    abort ();

  return 0;
}
