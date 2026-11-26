#pragma once

#include <cstddef>

// For n > 0, SAXPY's three arrays must be pairwise disjoint, and stencil output
// must not overlap its input. Dot-product inputs are read-only and may overlap
// each other. For n == 0, pointers are not dereferenced and may be null.
extern "C" void kernelforge_saxpy(std::size_t n, float alpha,
                                  const float *__restrict x,
                                  const float *__restrict y,
                                  float *__restrict output);
extern "C" float kernelforge_dot(std::size_t n, const float *x, const float *y);
extern "C" void kernelforge_stencil(std::size_t n,
                                    const float *__restrict input,
                                    float *__restrict output);

// Independent scalar implementations used only as correctness references.
extern "C" void kernelforge_reference_saxpy(std::size_t n, float alpha,
                                            const float *x, const float *y,
                                            float *output);
extern "C" float kernelforge_reference_dot(std::size_t n, const float *x,
                                           const float *y);
extern "C" void kernelforge_reference_stencil(std::size_t n, const float *input,
                                              float *output);
