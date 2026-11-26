#include <algorithm>
#include <array>
#include <chrono>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <iomanip>
#include <iostream>
#include <limits>
#include <string>
#include <vector>

static_assert(sizeof(std::size_t) == 8, "M3c requires the recorded 64-bit ABI");
static_assert(sizeof(std::int8_t) == 1, "destination must be 8-bit signed");

using Kernel = void (*)(std::size_t, const float *, std::int8_t *);

extern "C" void kernelforge_sat_i8_manual(std::size_t, const float *,
                                          std::int8_t *);
extern "C" void kernelforge_sat_i8_intrinsic(std::size_t, const float *,
                                             std::int8_t *);

namespace {

const std::array<float, 39> EdgeCases = {
    -std::numeric_limits<float>::infinity(),
    -1.0e30f,
    -129.0f,
    std::nextafter(-128.0f, -std::numeric_limits<float>::infinity()),
    -128.0f,
    std::nextafter(-128.0f, std::numeric_limits<float>::infinity()),
    -127.999f,
    -3.001f,
    -3.0f,
    -2.999f,
    -1.001f,
    -1.0f,
    -0.999f,
    -0.5f,
    -0.0f,
    0.0f,
    0.5f,
    0.999f,
    1.0f,
    1.001f,
    2.999f,
    3.0f,
    3.001f,
    126.999f,
    std::nextafter(127.0f, -std::numeric_limits<float>::infinity()),
    127.0f,
    std::nextafter(127.0f, std::numeric_limits<float>::infinity()),
    127.5f,
    128.0f,
    129.0f,
    1.0e30f,
    std::numeric_limits<float>::infinity(),
    std::numeric_limits<float>::quiet_NaN(),
    -64.75f,
    -0.25f,
    0.25f,
    63.75f,
    100.125f,
    -100.125f,
};

constexpr std::array<std::size_t, 28> CorrectnessSizes = {
    0,    1,    2,    3,    4,    5,    7,    8,    9,    15,
    16,   17,   31,   32,   33,   63,   64,   65,   127,  128,
    129,  255,  256,  257,  4095, 4096, 4097, 8388608,
};

constexpr std::array<std::size_t, 2> BenchmarkSizes = {4096, 8388608};
constexpr std::size_t WarmupPairs = 6;
constexpr std::size_t CalibrationPairs = 5;
constexpr std::uint64_t TargetSampleNanoseconds = 20000000;

struct Variant {
  const char *name;
  Kernel function;
};

struct Sample {
  std::size_t size;
  std::uint64_t repetitions;
  std::size_t pair;
  const char *first;
  std::uint64_t manual_total_ns;
  std::uint64_t intrinsic_total_ns;
};

void fill_benchmark_input(std::vector<float> &input);

std::int8_t scalar_reference(float value) {
  if (std::isnan(value))
    return 0;

  // Double precision keeps the oracle separate from the kernel's float
  // compares/selects. Convert only after truncation is inside the int8 range.
  const double truncated = std::trunc(static_cast<double>(value));
  if (truncated > 127.0)
    return 127;
  if (truncated < -128.0)
    return -128;
  return static_cast<std::int8_t>(truncated);
}

bool run_correctness() {
  const std::array<Variant, 2> variants = {{
      {"manual", kernelforge_sat_i8_manual},
      {"intrinsic", kernelforge_sat_i8_intrinsic},
  }};

  for (std::size_t n : CorrectnessSizes) {
    std::vector<float> input(n);
    std::vector<std::int8_t> manual(n);
    std::vector<std::int8_t> intrinsic(n);
    for (std::size_t i = 0; i < n; ++i)
      input[i] = EdgeCases[i % EdgeCases.size()];

    const float *input_data = n == 0 ? nullptr : input.data();
    std::int8_t *manual_data = n == 0 ? nullptr : manual.data();
    std::int8_t *intrinsic_data = n == 0 ? nullptr : intrinsic.data();
    for (const Variant &variant : variants) {
      std::int8_t *output = variant.name[0] == 'm' ? manual_data : intrinsic_data;
      variant.function(n, input_data, output);
    }

    for (std::size_t i = 0; i < n; ++i) {
      const std::int8_t expected = scalar_reference(input[i]);
      if (manual[i] != expected || intrinsic[i] != expected) {
        std::cerr << "correctness failure: n=" << n << " i=" << i
                  << " input=" << std::hexfloat << input[i] << std::defaultfloat
                  << " expected=" << static_cast<int>(expected)
                  << " manual=" << static_cast<int>(manual[i])
                  << " intrinsic=" << static_cast<int>(intrinsic[i]) << '\n';
        return false;
      }
    }
  }

  for (std::size_t n : BenchmarkSizes) {
    std::vector<float> input(n);
    std::vector<std::int8_t> manual(n);
    std::vector<std::int8_t> intrinsic(n);
    fill_benchmark_input(input);
    kernelforge_sat_i8_manual(n, input.data(), manual.data());
    kernelforge_sat_i8_intrinsic(n, input.data(), intrinsic.data());
    for (std::size_t i = 0; i < n; ++i) {
      const std::int8_t expected = scalar_reference(input[i]);
      if (manual[i] != expected || intrinsic[i] != expected) {
        std::cerr << "benchmark-input correctness failure: n=" << n
                  << " i=" << i << " input=" << std::hexfloat << input[i]
                  << std::defaultfloat << " expected=" << static_cast<int>(expected)
                  << " manual=" << static_cast<int>(manual[i])
                  << " intrinsic=" << static_cast<int>(intrinsic[i]) << '\n';
        return false;
      }
    }
  }

  std::cout << "PASS: 39 boundary inputs across 28 sizes plus both benchmark "
               "inputs; double-truncation scalar oracle\n";
  return true;
}

void fill_benchmark_input(std::vector<float> &input) {
  for (std::size_t i = 0; i < input.size(); ++i) {
    if (i % 257 == 0) {
      input[i] = EdgeCases[(i / 257) % EdgeCases.size()];
      continue;
    }

    const std::uint32_t state = static_cast<std::uint32_t>(i) * 1664525u + 1013904223u;
    const std::int32_t thousandths =
        static_cast<std::int32_t>(state % 320001u) - 160000;
    input[i] = static_cast<float>(thousandths) * 0.001f;
  }
}

std::uint64_t checksum(const std::vector<std::int8_t> &output) {
  std::uint64_t value = 14695981039346656037ull;
  for (std::int8_t element : output) {
    value ^= static_cast<std::uint8_t>(element);
    value *= 1099511628211ull;
  }
  return value;
}

std::uint64_t time_batch(Kernel kernel, std::size_t n,
                         const std::vector<float> &input,
                         std::vector<std::int8_t> &output,
                         std::uint64_t repetitions) {
  using Clock = std::chrono::steady_clock;
  const auto begin = Clock::now();
  for (std::uint64_t i = 0; i < repetitions; ++i)
    kernel(n, input.data(), output.data());
  const auto end = Clock::now();
  return static_cast<std::uint64_t>(
      std::chrono::duration_cast<std::chrono::nanoseconds>(end - begin).count());
}

double median(std::vector<double> values) {
  std::sort(values.begin(), values.end());
  const std::size_t middle = values.size() / 2;
  if (values.size() % 2 != 0)
    return values[middle];
  return (values[middle - 1] + values[middle]) / 2.0;
}

std::uint64_t calibrate_repetitions(std::size_t n,
                                    const std::vector<float> &input,
                                    std::vector<std::int8_t> &manual_output,
                                    std::vector<std::int8_t> &intrinsic_output,
                                    std::size_t order_offset) {
  std::vector<double> manual_times;
  std::vector<double> intrinsic_times;
  manual_times.reserve(CalibrationPairs);
  intrinsic_times.reserve(CalibrationPairs);
  for (std::size_t pair = 0; pair < CalibrationPairs; ++pair) {
    std::uint64_t manual_ns;
    std::uint64_t intrinsic_ns;
    if ((pair + order_offset) % 2 == 0) {
      manual_ns = time_batch(kernelforge_sat_i8_manual, n, input, manual_output, 1);
      intrinsic_ns = time_batch(kernelforge_sat_i8_intrinsic, n, input,
                                intrinsic_output, 1);
    } else {
      intrinsic_ns = time_batch(kernelforge_sat_i8_intrinsic, n, input,
                                intrinsic_output, 1);
      manual_ns = time_batch(kernelforge_sat_i8_manual, n, input, manual_output, 1);
    }
    manual_times.push_back(static_cast<double>(manual_ns));
    intrinsic_times.push_back(static_cast<double>(intrinsic_ns));
  }

  const double slower_ns = std::max(median(manual_times), median(intrinsic_times));
  const double needed = static_cast<double>(TargetSampleNanoseconds) /
                        std::max(1.0, slower_ns);
  return std::max<std::uint64_t>(1, static_cast<std::uint64_t>(std::ceil(needed)));
}

bool run_benchmark(std::size_t pairs, std::size_t order_offset) {
  std::vector<Sample> samples;
  samples.reserve(BenchmarkSizes.size() * pairs);

  for (std::size_t size_index = 0; size_index < BenchmarkSizes.size(); ++size_index) {
    const std::size_t n = BenchmarkSizes[size_index];
    std::vector<float> input(n);
    std::vector<std::int8_t> manual_output(n);
    std::vector<std::int8_t> intrinsic_output(n);
    fill_benchmark_input(input);

    for (std::size_t warmup = 0; warmup < WarmupPairs; ++warmup) {
      if ((warmup + order_offset + size_index) % 2 == 0) {
        kernelforge_sat_i8_manual(n, input.data(), manual_output.data());
        kernelforge_sat_i8_intrinsic(n, input.data(), intrinsic_output.data());
      } else {
        kernelforge_sat_i8_intrinsic(n, input.data(), intrinsic_output.data());
        kernelforge_sat_i8_manual(n, input.data(), manual_output.data());
      }
    }

    const std::uint64_t repetitions = calibrate_repetitions(
        n, input, manual_output, intrinsic_output,
        order_offset + size_index);
    for (std::size_t pair = 0; pair < pairs; ++pair) {
      const bool manual_first = (pair + order_offset + size_index) % 2 == 0;
      std::uint64_t manual_ns;
      std::uint64_t intrinsic_ns;
      if (manual_first) {
        manual_ns = time_batch(kernelforge_sat_i8_manual, n, input,
                               manual_output, repetitions);
        intrinsic_ns = time_batch(kernelforge_sat_i8_intrinsic, n, input,
                                  intrinsic_output, repetitions);
      } else {
        intrinsic_ns = time_batch(kernelforge_sat_i8_intrinsic, n, input,
                                  intrinsic_output, repetitions);
        manual_ns = time_batch(kernelforge_sat_i8_manual, n, input,
                               manual_output, repetitions);
      }
      samples.push_back({n, repetitions, pair,
                         manual_first ? "manual" : "intrinsic",
                         manual_ns, intrinsic_ns});
    }

    if (manual_output != intrinsic_output) {
      std::cerr << "post-benchmark output mismatch at n=" << n << '\n';
      return false;
    }
    std::cerr << "CHECKSUM n=" << n << " manual=" << checksum(manual_output)
              << " intrinsic=" << checksum(intrinsic_output) << '\n';
  }

  std::cout << "size,repetitions,pair,first_variant,manual_total_ns,"
               "intrinsic_total_ns,manual_ns_per_call,intrinsic_ns_per_call\n";
  std::cout << std::fixed << std::setprecision(2);
  for (const Sample &sample : samples) {
    std::cout << sample.size << ',' << sample.repetitions << ',' << sample.pair
              << ',' << sample.first << ',' << sample.manual_total_ns << ','
              << sample.intrinsic_total_ns << ','
              << static_cast<double>(sample.manual_total_ns) / sample.repetitions
              << ','
              << static_cast<double>(sample.intrinsic_total_ns) / sample.repetitions
              << '\n';
  }
  return true;
}

} // namespace

int main(int argc, char **argv) {
  if (argc == 2 && std::string(argv[1]) == "--correctness-only")
    return run_correctness() ? 0 : 1;
  if (argc == 4 && std::string(argv[1]) == "--benchmark") {
    const std::size_t pairs = static_cast<std::size_t>(std::stoull(argv[2]));
    const std::size_t offset = static_cast<std::size_t>(std::stoull(argv[3]));
    if (pairs == 0) {
      std::cerr << "pair count must be positive\n";
      return 2;
    }
    return run_benchmark(pairs, offset) ? 0 : 1;
  }
  std::cerr << "usage: benchmark --correctness-only | --benchmark PAIRS ORDER_OFFSET\n";
  return 2;
}
