#include <stdio.h>

int main(void)
{
#pragma omp parallel
  puts("Hello, World!\n");

  return 0;
}
