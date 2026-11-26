/* Freestanding oracle harness for QEMU's RV64V system emulator. */
_Static_assert(sizeof(unsigned long) == 8, "RV64 loop count must be 64-bit");
_Static_assert(sizeof(signed char) == 1, "destination must be int8_t-sized");

void kernelforge_sat_i8_manual(unsigned long, const float *, signed char *);
void kernelforge_sat_i8_intrinsic(unsigned long, const float *, signed char *);

static const float Cases[] = {
    -__builtin_inff(),
    -1.0e30f,
    -128.75f,
    -128.0000152587890625f,
    -128.0f,
    -127.999f,
    -1.9f,
    -0.5f,
    -0.0f,
    0.0f,
    0.5f,
    1.9f,
    126.999f,
    127.0f,
    127.00000762939453125f,
    127.5f,
    128.0f,
    1.0e30f,
    __builtin_inff(),
    __builtin_nanf(""),
};

static const signed char Expected[] = {
    -128, -128, -128, -128, -128, -127, -1, 0, 0, 0,
    0,    1,    126,  127,  127,  127,  127, 127, 127, 0,
};

static const unsigned long Sizes[] = {
    0, 1, 2, 3, 4, 5, 7, 8, 9, 15, 16, 17, 31, 32, 33, 63, 64, 65, 257,
    4097,
};

static float Input[4097];
static signed char ManualOutput[4097];
static signed char IntrinsicOutput[4097];

static int check_size(unsigned long n) {
  const unsigned long case_count = sizeof(Cases) / sizeof(Cases[0]);
  for (unsigned long i = 0; i < n; ++i)
    Input[i] = Cases[(i * 7 + n) % case_count];

  kernelforge_sat_i8_manual(n, Input, ManualOutput);
  kernelforge_sat_i8_intrinsic(n, Input, IntrinsicOutput);
  for (unsigned long i = 0; i < n; ++i) {
    const signed char expected = Expected[(i * 7 + n) % case_count];
    if (ManualOutput[i] != expected || IntrinsicOutput[i] != expected)
      return 0;
  }
  return 1;
}

int m3b_test(void) {
  /* Empty calls also exercise the no-access/null-pointer contract. */
  kernelforge_sat_i8_manual(0, (const float *)0, (signed char *)0);
  kernelforge_sat_i8_intrinsic(0, (const float *)0, (signed char *)0);
  for (unsigned long i = 0; i < sizeof(Sizes) / sizeof(Sizes[0]); ++i) {
    if (!check_size(Sizes[i]))
      return 1;
  }
  return 0;
}
