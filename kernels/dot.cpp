#include "kernel_api.hpp"

extern "C" float kernelforge_dot(std::size_t n, const float *x,
                                 const float *y) {
  float sum = 0.0f;
  for (std::size_t i = 0; i < n; ++i)
    sum += x[i] * y[i];
  return sum;
}
