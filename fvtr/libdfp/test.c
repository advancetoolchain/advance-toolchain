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

#ifndef __STDC_WANT_DEC_FP__
#error "Compilation parameter missing: -D__STDC_WANT_DEC_FP__=1"
#endif

/* Try to include dfp headers without specifying the complete path */
#include <fenv.h>
#include <math.h>
#include <stdlib.h>
#include <wchar.h>

/* Test if the headers from libdfp have indeed been included */
#ifndef _DFP_FENV_H
#error "Header file dfp/fenv.h should have set _DFP_FENV_H"
#endif
#ifndef _DFP_MATH_H
#error "Header file dfp/math.h should have set _DFP_MATH_H"
#endif
#ifndef _DFP_STDLIB_H
#error "Header file dfp/stdlib.h should have set _DFP_STDLIB_H"
#endif
#ifndef _DFP_WCHAR_H
#error "Header file dfp/wchar.h should have set _DFP_WCHAR_H"
#endif

int main ()
{
	_Decimal64 d64 = 2.22222222222DD;

	sqrtd64(d64);

	return 0;
}
