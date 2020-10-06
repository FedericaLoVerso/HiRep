/***************************************************************************\
* Copyright (c) 2008, Claudio Pica                                          *   
* All rights reserved.                                                      * 
\***************************************************************************/

#ifndef LINEAR_ALGEBRA_H
#define LINEAR_ALGEBRA_H

#ifdef __cplusplus
extern "C" {
#endif

/* 
 * LINEAR ALGEBRA FUNCTIONS ARE DEFINED IN THE TEMPLATE
 *
 * TMPL/linear_algebra.h.sdtmpl
 *
 */

#include "suN.h"
#include "spinor_field.h"

/* double precision */
#define _SPINOR_FIELD_TYPE spinor_field
#define _FUNC(a) a##_f
#define _REAL double
#define _COMPLEX double complex
#include "TMPL/linear_algebra.h.sdtmpl"
#undef _SPINOR_FIELD_TYPE
#undef _FUNC
#undef _REAL
#undef _COMPLEX

/* single precision */
#define _SPINOR_FIELD_TYPE spinor_field_flt
#define _FUNC(a) a##_f_flt
#define _REAL float
#define _COMPLEX float complex
#include "TMPL/linear_algebra.h.sdtmpl"
#undef _SPINOR_FIELD_TYPE
#undef _FUNC
#undef _REAL
#undef _COMPLEX

#ifdef __cplusplus
}
#endif

#endif
