#include "kernel_api.hpp"

#include <cmath>
#include <cstddef>
#include <cstdint>
#include <iostream>
#include <vector>

namespace {

constexpr float AbsoluteTolerance = 1.0e-4f;
constexpr float RelativeTolerance = 2.0e-5f;
constexpr float SaxpyAlpha = 0.73f;

#define KERNELFORGE_TEST_SIZE(n) n,
constexpr std::size_t Sizes[] = {
#include "workload_sizes.inc"
};
#undef KERNELFORGE_TEST_SIZE

float deterministicValue(std::size_t index, std::uint32_t salt) {
  const std::uint32_t mixed =
      (static_cast<std::uint32_t>(index) * 37u + salt * 19u) % 127u;
  const int centered = static_cast<int>(mixed) - 63;
  return static_cast<float>(centered) / 79.0f;
}

std::vector<float> makeInput(std::size_t n, std::uint32_t salt) {
  std::vector<float> values(n);
  for (std::size_t i = 0; i < n; ++i)
    values[i] = deterministicValue(i, salt);
  return values;
}

bool closeEnough(float actual, float expected) {
  const float difference = std::fabs(actual - expected);
  return difference <=
         AbsoluteTolerance + RelativeTolerance * std::fabs(expected);
}

bool checkArray(const char *kernel, std::size_t n,
                const std::vector<float> &actual,
                const std::vector<float> &expected) {
  for (std::size_t i = 0; i < n; ++i) {
    if (!closeEnough(actual[i], expected[i])) {
      std::cerr << kernel << " mismatch at size=" << n << " index=" << i
                << ": actual=" << actual[i] << " expected=" << expected[i]
                << '\n';
      return false;
    }
  }
  return true;
}

bool runCase(std::size_t n) {
  const std::vector<float> x = makeInput(n, 3);
  const std::vector<float> y = makeInput(n, 11);
  const std::vector<float> stencilInput = makeInput(n, 29);
  std::vector<float> saxpyActual(n, -99.0f);
  std::vector<float> saxpyExpected(n, -99.0f);
  std::vector<float> stencilActual(n, -99.0f);
  std::vector<float> stencilExpected(n, -99.0f);

  const float *xData = n ? x.data() : nullptr;
  const float *yData = n ? y.data() : nullptr;
  const float *stencilData = n ? stencilInput.data() : nullptr;
  float *saxpyActualData = n ? saxpyActual.data() : nullptr;
  float *saxpyExpectedData = n ? saxpyExpected.data() : nullptr;
  float *stencilActualData = n ? stencilActual.data() : nullptr;
  float *stencilExpectedData = n ? stencilExpected.data() : nullptr;

  kernelforge_saxpy(n, SaxpyAlpha, xData, yData, saxpyActualData);
  kernelforge_reference_saxpy(n, SaxpyAlpha, xData, yData, saxpyExpectedData);
  if (!checkArray("saxpy", n, saxpyActual, saxpyExpected))
    return false;

  const float dotActual = kernelforge_dot(n, xData, yData);
  const float dotExpected = kernelforge_reference_dot(n, xData, yData);
  if (!closeEnough(dotActual, dotExpected)) {
    std::cerr << "dot mismatch at size=" << n << ": actual=" << dotActual
              << " expected=" << dotExpected << '\n';
    return false;
  }
  const float dotAliasedActual = kernelforge_dot(n, xData, xData);
  const float dotAliasedExpected = kernelforge_reference_dot(n, xData, xData);
  if (!closeEnough(dotAliasedActual, dotAliasedExpected)) {
    std::cerr << "dot with overlapping read-only inputs mismatch at size=" << n
              << ": actual=" << dotAliasedActual
              << " expected=" << dotAliasedExpected << '\n';
    return false;
  }

  kernelforge_stencil(n, stencilData, stencilActualData);
  kernelforge_reference_stencil(n, stencilData, stencilExpectedData);
  if (!checkArray("stencil", n, stencilActual, stencilExpected))
    return false;

  if (n > 0 && !closeEnough(stencilActual.front(), stencilInput.front())) {
    std::cerr << "stencil left boundary changed at size=" << n << '\n';
    return false;
  }
  if (n > 1 && !closeEnough(stencilActual.back(), stencilInput.back())) {
    std::cerr << "stencil right boundary changed at size=" << n << '\n';
    return false;
  }

  return true;
}

} // namespace

int main() {
  // Four floats form one 128-bit AArch64 NEON vector. These sizes straddle
  // several vector-width boundaries and include odd, small, and empty inputs.
  for (std::size_t n : Sizes) {
    if (!runCase(n))
      return 1;
  }

  std::cout << "Passed SAXPY, dot, and stencil for "
            << (sizeof(Sizes) / sizeof(Sizes[0]))
            << " sizes (0 through 4097).\n";
  return 0;
}
