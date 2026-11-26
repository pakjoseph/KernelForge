#include "kernel_api.hpp"

extern "C" void kernelforge_stencil(std::size_t n,
                                    const float *__restrict input,
                                    float *__restrict output) {
  if (n == 0)
    return;

  output[0] = input[0];
  if (n == 1)
    return;

  for (std::size_t i = 1; i < n - 1; ++i)
    output[i] = (input[i - 1] + input[i] + input[i + 1]) / 3.0f;

  output[n - 1] = input[n - 1];
}
