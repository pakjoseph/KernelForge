/*
 * Freestanding RV64 port of the M3a manual conversion kernel.
 * Contract: NaN -> 0; clamp to [-128, 127]; truncate toward zero.
 * The cast is in range after the explicit NaN check and clamps.
 */
_Static_assert(sizeof(unsigned long) == 8, "RV64 loop count must be 64-bit");
_Static_assert(sizeof(signed char) == 1, "destination must be int8_t-sized");

void kernelforge_sat_i8_manual(unsigned long n,
                               const float *__restrict input,
                               signed char *__restrict output) {
  for (unsigned long i = 0; i < n; ++i) {
    float value = input[i];
    if (value != value) {
      output[i] = 0;
      continue;
    }
    if (value > 127.0f)
      value = 127.0f;
    if (value < -128.0f)
      value = -128.0f;
    output[i] = (signed char)value;
  }
}
