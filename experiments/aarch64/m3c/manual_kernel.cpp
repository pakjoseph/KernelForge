#include <cstddef>
#include <cstdint>

static_assert(sizeof(std::size_t) == 8, "M3c requires the recorded 64-bit ABI");
static_assert(sizeof(std::int8_t) == 1, "destination must be 8-bit signed");

// Reproduces the M3a manual form. The noinline boundary keeps the kernel
// separately identifiable in the linked benchmark executable.
extern "C" __attribute__((noinline)) void kernelforge_sat_i8_manual(
    std::size_t n, const float *__restrict input,
    std::int8_t *__restrict output) {
  for (std::size_t i = 0; i < n; ++i) {
    float value = input[i];
    if (value != value) {
      output[i] = 0;
      continue;
    }
    if (value > 127.0f)
      value = 127.0f;
    if (value < -128.0f)
      value = -128.0f;
    output[i] = static_cast<std::int8_t>(value);
  }
}
