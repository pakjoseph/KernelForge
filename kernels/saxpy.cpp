#include "kernel_api.hpp"

extern "C" void kernelforge_saxpy(std::size_t n, float alpha,
                                  const float *__restrict x,
                                  const float *__restrict y,
                                  float *__restrict output) {
  for (std::size_t i = 0; i < n; ++i)
    output[i] = alpha * x[i] + y[i];
}
