// A GCC supporting __builtin_cpu_is() has a mechanism to detect when an
// invalid parameter is passed and should fail at compile time.
// However, if GCC doesn't support this builtin or if GCC does support, but
// glibc doesn't, this code will compile cleanly.
// So, this test pass when the build fails.

int
foo (void)
{
  return __builtin_cpu_is ("foobar") != 0;
}
