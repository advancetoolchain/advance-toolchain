/*
 Copyright (c) [2017-18] IBM Corporation.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

 vec_int64_dummy.c

 Contributors:
      IBM Corporation, Steven Munroe
      Created on: Jul 31, 2017
 */

#include <stdint.h>
#include <stdio.h>
#include <fenv.h>
#include <float.h>
#include <math.h>

//#define __DEBUG_PRINT__

#include <pveclib/vec_f64_ppc.h>

int
test512_all_f64_nan (vf64_t val0, vf64_t val1, vf64_t val2, vf64_t val3)
{
  const vb64_t alltrue = { -1, -1 };
  vb64_t nan0, nan1, nan2, nan3;

  nan0 = vec_isnanf64 (val0);
  nan1 = vec_isnanf64 (val1);
  nan2 = vec_isnanf64 (val2);
  nan3 = vec_isnanf64 (val3);
/* Only newest compilers support vec_and for vector bool long long.
   So cast to vector bool int then back as a compiler work around.
   Here we just want to see what the various compilers will do.  */
  nan0 = (vb64_t)vec_and ((vb32_t)nan0, (vb32_t)nan1);
  nan2 = (vb64_t)vec_and ((vb32_t)nan2, (vb32_t)nan3);
  nan0 = (vb64_t)vec_and ((vb32_t)nan2, (vb32_t)nan0);

#ifdef _ARCH_PWR8
  return vec_all_eq(nan0, alltrue);
#else
  return vec_cmpud_all_eq((vui64_t)nan0, (vui64_t)alltrue);
#endif
}

int
test_all_f64_finite (vf64_t value)
{
  return (vec_all_isfinitef64 (value));
}

int
test_all_f64_inf (vf64_t value)
{
  return (vec_all_isinff64 (value));
}

int
test_all_f64_nan (vf64_t value)
{
  return (vec_all_isnanf64 (value));
}

int
test_all_f64_norm (vf64_t value)
{
  return (vec_all_isnormalf64 (value));
}

int
test_all_f64_subnorm (vf64_t value)
{
  return (vec_all_issubnormalf64 (value));
}

int
test_all_f64_zero (vf64_t value)
{
  return (vec_all_iszerof64 (value));
}

int
test_any_f64_finite (vf64_t value)
{
  return (vec_any_isfinitef64 (value));
}
int
test_any_f64_inf (vf64_t value)
{
  return (vec_any_isinff64 (value));
}

int
test_any_f64_nan (vf64_t value)
{
  return (vec_any_isnanf64 (value));
}

int
test_any_f64_norm (vf64_t value)
{
  return (vec_any_isnormalf64 (value));
}

int
test_any_f64_subnorm (vf64_t value)
{
  return (vec_any_issubnormalf64 (value));
}

int
test_any_f64_zero (vf64_t value)
{
  return (vec_any_iszerof64 (value));
}

vb64_t
test_pred_f64_finite (vf64_t value)
{
  return (vec_isfinitef64 (value));
}

vb64_t
test_pred_f64_inf (vf64_t value)
{
  return (vec_isinff64 (value));
}

vb64_t
test_pred_f64_nan (vf64_t value)
{
  return (vec_isnanf64 (value));
}

vb64_t
test_pred_f64_normal (vf64_t value)
{
  return (vec_isnormalf64 (value));
}

vb64_t
test_pred_f64_subnormal (vf64_t value)
{
  return (vec_issubnormalf64 (value));
}

vb64_t
test_pred_f64_zero (vf64_t value)
{
  return (vec_iszerof64 (value));
}

vui64_t
test_fpclassify_f64 (vf64_t value)
{
  const vui64_t VFP_NAN =
    { FP_NAN, FP_NAN };
  const vui64_t VFP_INFINITE =
    { FP_INFINITE, FP_INFINITE };
  const vui64_t VFP_ZERO =
    { FP_ZERO, FP_ZERO };
  const vui64_t VFP_SUBNORMAL =
    { FP_SUBNORMAL, FP_SUBNORMAL };
  const vui64_t VFP_NORMAL =
    { FP_NORMAL, FP_NORMAL };
  /* FP_NAN should be 0.  */
  vui64_t result = VFP_NAN;
  vui64_t mask;

  mask = (vui64_t) vec_isinff64 (value);
  result = vec_sel (result, VFP_INFINITE, mask);
  mask = (vui64_t) vec_iszerof64 (value);
  result = vec_sel (result, VFP_ZERO, mask);
  mask = (vui64_t) vec_issubnormalf64 (value);
  result = vec_sel (result, VFP_SUBNORMAL, mask);
  mask = (vui64_t) vec_isnormalf64 (value);
  result = vec_sel (result, VFP_NORMAL, mask);

  return result;
}
/* dummy sinf64 example. From Posix:
 * If value is NaN then return a NaN.
 * If value is +-0.0 then return value.
 * If value is subnormal then return value.
 * If value is +-Inf then return a NaN.
 * Otherwise compute and return sin(value).
 */
vf64_t
test_vec_sinf64 (vf64_t value)
{
  const vf64_t vec_f0 = { 0.0, 0.0 };
  const vui64_t vec_f64_qnan =
    { 0x7ff8000000000000, 0x7ff8000000000000 };
  vf64_t result;
  vb64_t normmask, infmask;

  normmask = vec_isnormalf64 (value);
  if (vec_any_isnormalf64 (value))
    {
      /* replace non-normal input values with safe values.  */
      vf64_t safeval = vec_sel (vec_f0, value, normmask);
      /* body of vec_sin(safeval) computation elided for this example.  */
      result = vec_mul (safeval, safeval);
    }
  else
    result = value;

  /* merge non-normal input values back into result */
  result = vec_sel (value, result, normmask);
  /* Inf input value elements return quiet-nan.  */
  infmask = vec_isinff64 (value);
  result = vec_sel (result, (vf64_t) vec_f64_qnan, infmask);

  return result;
}

/* dummy cosf64 example. From Posix:
 * If value is NaN then return a NaN.
 * If value is +-0.0 then return 1.0.
 * If value is +-Inf then return a NaN.
 * Otherwise compute and return sin(value).
 */
vf64_t
test_vec_cosf64 (vf64_t value)
{
  vf64_t result;
  const vf64_t vec_f0 = { 0.0, 0.0 };
  const vf64_t vec_f1 = { 1.0, 1.0 };
  const vui64_t vec_f64_qnan =
    { 0x7ff8000000000000, 0x7ff8000000000000 };
  vb64_t finitemask, infmask, zeromask;

  finitemask = vec_isfinitef64 (value);
  if (vec_any_isfinitef64 (value))
    {
      /* replace non-finite input values with safe values.  */
      vf64_t safeval = vec_sel (vec_f0, value, finitemask);
      /* body of vec_sin(safeval) computation elided for this example.  */
      result = vec_mul (safeval, safeval);
    }
  else
    result = value;

  /* merge non-finite input values back into result */
  result = vec_sel (value, result, finitemask);
  /* Set +-0.0 input elements to exactly 1.0 in result.  */
  zeromask = vec_iszerof64 (value);
  result = vec_sel (result, vec_f1, zeromask);
  /* Set Inf input elements to quiet-nan in result.  */
  infmask = vec_isinff64 (value);
  result = vec_sel (result, (vf64_t) vec_f64_qnan, infmask);

  return result;
}

/* compiler scalar inline tests.  */
vf64_t
test_load_vf64 ( vf64_t *val)
{
  return *val;
}

int
test_f64_isfinite (double value)
{
  return (__builtin_isfinite (value));
}

int
test_f64_isinf (double value)
{
  return (__builtin_isinf (value));
}

int
test_f64_isnan (double value)
{
  return (__builtin_isnan (value));
}

int
test_f64_isnormal (double value)
{
  return (__builtin_isnormal (value));
}

vf64_t
test_ibm128_vf64_vec (long double lval)
{
  return (vec_unpack_longdouble (lval));
}

long double
test_vf64_ibm128_vec (vf64_t lval)
{
  return (vec_pack_longdouble (lval));
}

vf64_t
test_ibm128_vf64_asm (long double lval)
{
#ifdef _ARCH_PWR7
  vf64_t t;
  __asm__(
      "xxmrghd %x0,%1,%L1;\n"
      : "=wa" (t)
      : "f" (lval)
      : );
  return (t);
#else
  U_128 t;
  t.ldbl128 = lval;
  return (t.vf2);
#endif
}

long double
test_vf64_ibm128_asm (vf64_t lval)
{
#ifdef _ARCH_PWR7
  long double t;
  __asm__(
      "xxlor %0,%x1,%x1;\n"
      "\txxswapd %L0,%x1;\n"
      : "=f" (t)
      : "wa" (lval)
      : );
  return (t);
#else
  U_128 t;
  t.vf2 = lval;
  return (t.ldbl128);
#endif
}

#ifdef _ARCH_PWR8
/* POWER 64-bit (vector double) compiler tests.  */

vb64_t
__test_cmpeqdp (vf64_t a, vf64_t b)
{
  return vec_cmpeq (a, b);
}

vb64_t
__test_cmpgtdp (vf64_t a, vf64_t b)
{
  return vec_cmpgt (a, b);
}

vb64_t
__test_cmpltdp (vf64_t a, vf64_t b)
{
  return vec_cmplt (a, b);
}

vb64_t
__test_cmpgedp (vf64_t a, vf64_t b)
{
  return vec_cmpge (a, b);
}

vb64_t
__test_cmpledp (vf64_t a, vf64_t b)
{
  return vec_cmple (a, b);
}
#endif
