#include "kernel_api.hpp"

extern "C" void kernelforge_reference_saxpy(std::size_t n, float alpha,
                                            const float *x, const float *y,
                                            float *output) {
  for (std::size_t i = 0; i < n; ++i) {
    const float scaled = alpha * x[i];
    output[i] = scaled + y[i];
  }
}

extern "C" float kernelforge_reference_dot(std::size_t n, const float *x,
                                           const float *y) {
  float sum = 0.0f;
  for (std::size_t i = 0; i < n; ++i) {
    const float product = x[i] * y[i];
    sum = sum + product;
  }
  return sum;
}

extern "C" void kernelforge_reference_stencil(std::size_t n, const float *input,
                                              float *output) {
  if (n == 0)
    return;

  output[0] = input[0];
  if (n == 1)
    return;

  for (std::size_t i = 1; i < n - 1; ++i) {
    const float left_and_center = input[i - 1] + input[i];
    const float neighborhood = left_and_center + input[i + 1];
    output[i] = neighborhood / 3.0f;
  }

  output[n - 1] = input[n - 1];
}
