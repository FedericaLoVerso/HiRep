#ifndef LINEAR_ALGEBRA_GPU_CU
#define LINEAR_ALGEBRA_GPU_CU

#include "global.h"
#include "gpu.h"



//reduction of the last elements
template<typename REAL>
__device__ void warpReduce(volatile REAL* sdata, int tid){
  sdata[tid]+=sdata[tid+32];
  sdata[tid]+=sdata[tid+16];
  sdata[tid]+=sdata[tid+8];
  sdata[tid]+=sdata[tid+4];
  sdata[tid]+=sdata[tid+2];
  sdata[tid]+=sdata[tid+1];
}

//Global sum calculation
template<typename REAL>
__global__ void global_sum_gpu(REAL* in, REAL* out, int N){
  __shared__ REAL sdata[BLOCK_SIZE];
  int tid = threadIdx.x;
  int i;
  //  REAL res;
  sdata[tid]=in[tid];
  for (i=tid+BLOCK_SIZE;i<N;i+= BLOCK_SIZE){ // Sum over all blocks 
    sdata[tid]+=in[i];
  }
  __syncthreads();
  
  for (i = BLOCK_SIZE/2;i>32;i/=2){
    if (tid < i) sdata[tid]+=sdata[tid+i];
    __syncthreads();
  }
  if (tid<32){ //Unroll all the threads in a WARP
    warpReduce(sdata,tid);
  }
  __syncthreads();
  if (tid == 0)  out[0] = sdata[0];
}

//Reduction of the last elements
template<typename COMPLEX>
__device__ void warpReduce_complex(volatile COMPLEX* sdata, int tid){
  _complex_add(sdata[tid],sdata[tid],sdata[tid+32]);
  _complex_add(sdata[tid],sdata[tid],sdata[tid+16]);
  _complex_add(sdata[tid],sdata[tid],sdata[tid+8]);
  _complex_add(sdata[tid],sdata[tid],sdata[tid+4]);
  _complex_add(sdata[tid],sdata[tid],sdata[tid+2]);
  _complex_add(sdata[tid],sdata[tid],sdata[tid+1]);
}

//Global sum calculation
template<typename COMPLEX>
__global__ void global_sum_complex_gpu(COMPLEX* in, COMPLEX* out, int N){
  __shared__ COMPLEX sdata[BLOCK_SIZE];
  int tid = threadIdx.x;
  int i;
  //  REAL res;
  sdata[tid]=in[tid];
  for (i=tid+BLOCK_SIZE;i<N;i+= BLOCK_SIZE){ // Sum over all blocks 
    _complex_add(sdata[tid],sdata[tid],in[i]);    
  }
  __syncthreads();
  
  for (i = BLOCK_SIZE/2;i>32;i/=2){
    if (tid < i){
      _complex_add(sdata[tid],sdata[tid],sdata[tid+i]);
    }
    __syncthreads();
  }
  if (tid<32){ //Unroll all the threads in a WARP
    warpReduce_complex(sdata,tid);
  }
  __syncthreads();
  if (tid == 0)  out[0] = sdata[0];
}

/* Re <s1,s2> */
template<typename SPINOR_TYPE, typename REAL>
  __global__ void spinor_field_prod_re_gpu(SPINOR_TYPE* s1, SPINOR_TYPE* s2, REAL* resField,int N){
  int i = blockIdx.x*BLOCK_SIZE + threadIdx.x;
  if (i<N){
    _spinor_prod_re_f(resField[i],s1[i],s2[i]);
  }
}

/* Im <s1,s2> */
template<typename SPINOR_TYPE, typename REAL>
  __global__ void spinor_field_prod_im_gpu(SPINOR_TYPE* s1, SPINOR_TYPE* s2, REAL* resField,int N){
  int i = blockIdx.x*BLOCK_SIZE + threadIdx.x;
  if (i<N){
    _spinor_prod_im_f(resField[i],s1[i],s2[i]);
  }
}

/* <s1,s2> */
template< typename SPINOR_TYPE, typename COMPLEX >
  __global__ void spinor_field_prod_gpu(SPINOR_TYPE* s1, SPINOR_TYPE* s2, COMPLEX* resField,int N){
  int i = blockIdx.x*BLOCK_SIZE + threadIdx.x;
  if (i<N){
    _spinor_prod_f(resField[i],s1[i],s2[i]);
  }
}

/* Re <g5*s1,s2> */
template<typename SPINOR_TYPE, typename REAL>
  __global__ void spinor_field_g5_prod_re_gpu(SPINOR_TYPE* s1, SPINOR_TYPE* s2, REAL* resField,int N){
  int i = blockIdx.x*BLOCK_SIZE + threadIdx.x;
  if (i<N){
    _spinor_g5_prod_re_f(resField[i],s1[i],s2[i]);
  }
}

/* Im <g5*s1,s2> */
template<typename SPINOR_TYPE, typename REAL>
  __global__ void spinor_field_g5_prod_im_gpu(SPINOR_TYPE* s1, SPINOR_TYPE* s2, REAL* resField,int N){
  int i = blockIdx.x*BLOCK_SIZE + threadIdx.x;
  if (i<N){
    _spinor_g5_prod_im_f(resField[i],s1[i],s2[i]);
  }
}

/* Re <s1,s1> */ 
template<typename SPINOR_TYPE, typename REAL>
  __global__ void spinor_field_sqnorm_gpu(SPINOR_TYPE* s1, REAL* resField,int N){
  int i = blockIdx.x*BLOCK_SIZE + threadIdx.x;
  if (i<N){
    _spinor_prod_re_f(resField[i],s1[i],s1[i]);
  }
}

/* s1+=r*s2 r real */
template< typename SPINOR_TYPE, typename REAL >
__global__ void spinor_field_mul_add_assign_gpu(SPINOR_TYPE *s1, REAL r, SPINOR_TYPE *s2,int N){
  int i = blockIdx.x*BLOCK_SIZE + threadIdx.x;
  if (i<N) {
    _spinor_mul_add_assign_f(s1[i],r,s2[i]);
  }
}

/* s1=r*s2 c complex */
template< typename SPINOR_TYPE , typename REAL >
__global__ void spinor_field_mul_gpu(SPINOR_TYPE *s1, REAL r, SPINOR_TYPE *s2,int N){
  int i = blockIdx.x*BLOCK_SIZE + threadIdx.x;
  if (i<N) {
    _spinor_mul_f(s1[i],r,s2[i]);
  }
}

/* s1+=c*s2 c complex */
template< typename SPINOR_TYPE , typename COMPLEX >
__global__ void spinor_field_mulc_add_assign_gpu(SPINOR_TYPE *s1, COMPLEX c, SPINOR_TYPE *s2,int N){
  int i = blockIdx.x*BLOCK_SIZE + threadIdx.x;
  if (i<N) {
    _spinor_mulc_add_assign_f(s1[i],c,s2[i]);
  }
}

/* s1=c*s2 c complex */
template< typename SPINOR_TYPE, typename COMPLEX >
__global__ void spinor_field_mulc_gpu(SPINOR_TYPE *s1, COMPLEX c, SPINOR_TYPE *s2,int N){
  int i = blockIdx.x*BLOCK_SIZE + threadIdx.x;
  if (i<N) {
    _spinor_mulc_f(s1[i],c,s2[i]);
  }
}

/* r=s1+s2 */
template< typename SPINOR_TYPE>
__global__ void spinor_field_add_gpu(SPINOR_TYPE *r, SPINOR_TYPE *s1, SPINOR_TYPE *s2,int N){
  int i = blockIdx.x*BLOCK_SIZE + threadIdx.x;
  if (i<N) {
	 _spinor_add_f(r[i],s1[i],s2[i]);
	}
}

/* r=s1-s2 */
template< typename SPINOR_TYPE >
__global__ void spinor_field_sub_gpu(COMPLEX *r, COMPLEX* s1, COMPLEX *s2,int N){
  int i = blockIdx.x*BLOCK_SIZE + threadIdx.x;
  if (i<N) {
    _complex_sub(r[i],s1[i],s2[i]);
  }
}

/* s1+=s2 */
template< typename SPINOR_TYPE>
__global__ void spinor_field_add_assign_gpu(SPINOR_TYPE *s1, SPINOR_TYPE *s2,int N){
  int i = blockIdx.x*BLOCK_SIZE + threadIdx.x;
  if (i<N) {
	 _spinor_add_assign_f(s1[i],s2[i]);
	}
}

/* s1-=s2 */
template< typename SPINOR_TYPE >
__global__ void spinor_field_sub_assign_gpu(SPINOR_TYPE* s1, SPINOR_TYPE *s2,int N){
  int i = blockIdx.x*BLOCK_SIZE + threadIdx.x;
  if (i<N) {
    _spinor_sub_assign_f(s1[i],s2[i]);
  }
}

/* s1=0 */
template< typename SPINOR_TYPE>
__global__ void spinor_field_zero_gpu(SPINOR_TYPE *s1,int N){
  int i = blockIdx.x*BLOCK_SIZE + threadIdx.x;
  if (i<N) {
    _spinor_zero_f(s1[i]);
  }
}

/* s1=-s2 */
template< typename SPINOR_TYPE >
__global__ void spinor_field_minus_gpu(SPINOR_TYPE* s1, SPINOR_TYPE *s2,int N){
  int i = blockIdx.x*BLOCK_SIZE + threadIdx.x;
  if (i<N) {
    _spinor_minus_f(s1[i],s2[i]);
  }
}

/* s1=r1*s2+r2*s3 */
template< typename SPINOR_TYPE , typename REAL >
__global__ void spinor_field_lc_gpu(SPINOR_TYPE *s1, REAL r1, SPINOR_TYPE *s2, REAL r2, SPINOR_TYPE *s3, int N){
  int i = blockIdx.x*BLOCK_SIZE + threadIdx.x;
  if (i<N) {
    _spinor_lc_f(s1[i],r1,s2[i],r2,s3[i]);
  }
}

/* s1+=r*s2 r real */
template< typename SPINOR_TYPE, typename REAL >
__global__ void spinor_field_lc_add_assign_gpu(SPINOR_TYPE *s1, REAL r1, SPINOR_TYPE *s2, REAL r2, SPINOR_TYPE *s3, int N){
  int i = blockIdx.x*BLOCK_SIZE + threadIdx.x;
  if (i<N) {
    _spinor_lc_add_assign_f(s1[i],r1,s2[i],r2,s3[i]);
  }
}


/* s1=cd1*s2+cd2*s3 cd1, cd2 complex*/
template< typename SPINOR_TYPE , typename COMPLEX >
__global__ void spinor_field_clc_gpu(SPINOR_TYPE *s1, COMPLEX c1, SPINOR_TYPE *s2, COMPLEX c2, SPINOR_TYPE *s3, int N){
  int i = blockIdx.x*BLOCK_SIZE + threadIdx.x;
  if (i<N) {
    _spinor_clc_f(s1[i],c1,s2[i],c2,s3[i]);
  }
}

/* s1+=r*s2 r real */
template< typename SPINOR_TYPE, typename COMPLEX >
__global__ void spinor_field_clc_add_assign_gpu(SPINOR_TYPE *s1, COMPLEX c1, SPINOR_TYPE *s2, COMPLEX c2, SPINOR_TYPE *s3, int N){
  int i = blockIdx.x*BLOCK_SIZE + threadIdx.x;
  if (i<N) {
    _spinor_clc_add_assign_f(s1[i],c1,s2[i],c2,s3[i]);
  }
}

/* s1=g5*s2  */
template< typename SPINOR_TYPE>
__global__ void spinor_field_g5_gpu(SPINOR_TYPE *s1, SPINOR_TYPE *s2,int N){
  int i = blockIdx.x*BLOCK_SIZE + threadIdx.x;
  if (i<N) {
    _spinor_g5_f(s1[i],s2[i]);
  }
}


/* s1=g5*s1 */
template< typename SPINOR_TYPE >
__global__ void spinor_field_g5_assign_gpu(SPINOR_TYPE* s1,int N){
  int i = blockIdx.x*BLOCK_SIZE + threadIdx.x;
  if (i<N) {
    _spinor_g5_assign_f(s1[i]);
  }
}

/* tools per eva.c  */
template< typename SPINOR_TYPE , typename REAL >
__global__ void spinor_field_lc1_gpu(REAL r, SPINOR_TYPE *s1, SPINOR_TYPE *s2, int N){
  int i = blockIdx.x*BLOCK_SIZE + threadIdx.x;
  if (i<N) {
    _spinor_mul_add_assign_f(s1[i],r,s2[i]);
  }
}


template< typename SPINOR_TYPE, typename REAL >
__global__ void spinor_field_lc2_gpu(REAL r1, REAL r2, SPINOR_TYPE *s1, SPINOR_TYPE *s2, int N){
  int i = blockIdx.x*BLOCK_SIZE + threadIdx.x;
  if (i<N) {
    _spinor_lc_f(s1[i],r1,s1[i],r2,s2[i]);
  }
}

template< typename SPINOR_TYPE , typename REAL >
__global__ void spinor_field_lc3_gpu(REAL r1,REAL r2, SPINOR_TYPE *s1, SPINOR_TYPE *s2, SPINOR_TYPE *s3, int N){
  int i = blockIdx.x*BLOCK_SIZE + threadIdx.x;
  if (i<N) {
    _spinor_lc_add_assign_f(s3[i],r1,s1[i],r2,s2[i]);
    _spinor_minus_f(s3[i],s3[i]);
  }
}

/* c1=0 */
/*
template< typename COMPLEX>
__global__ void complex_field_zero_gpu(COMPLEX *c1,int N){
  int i = blockIdx.x*BLOCK_SIZE + threadIdx.x;
  if (i<N) {
    c1[i].re=0;
    c1[i].im=0;
  }
}
*/


#endif
