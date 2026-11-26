cmake_minimum_required(VERSION 3.25)

project(KernelForge LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

find_package(LLVM 23.1.6 EXACT REQUIRED CONFIG)

if(NOT LLVM_PACKAGE_VERSION STREQUAL "23.1.6")
  message(FATAL_ERROR "KernelForge requires LLVM 23.1.6; found ${LLVM_PACKAGE_VERSION}")
endif()

if(NOT TARGET LLVM)
  message(FATAL_ERROR "The selected LLVM package does not export the shared LLVM target")
endif()

add_library(KernelAccessReport MODULE
  src/KernelAccessReport.cpp
)

target_include_directories(KernelAccessReport SYSTEM PRIVATE ${LLVM_INCLUDE_DIRS})
target_compile_definitions(KernelAccessReport PRIVATE ${LLVM_DEFINITIONS})
target_link_libraries(KernelAccessReport PRIVATE LLVM)
set_target_properties(KernelAccessReport PROPERTIES
  PREFIX ""
  OUTPUT_NAME "KernelAccessReport"
)

include(CTest)
find_package(Python3 COMPONENTS Interpreter REQUIRED)
find_program(OPT_EXECUTABLE NAMES opt HINTS "${LLVM_TOOLS_BINARY_DIR}" NO_DEFAULT_PATH REQUIRED)
find_program(FILECHECK_EXECUTABLE NAMES FileCheck HINTS "${LLVM_TOOLS_BINARY_DIR}" NO_DEFAULT_PATH REQUIRED)
find_program(LLVM_DIFF_EXECUTABLE NAMES llvm-diff HINTS "${LLVM_TOOLS_BINARY_DIR}" NO_DEFAULT_PATH REQUIRED)

add_library(KernelReference OBJECT
  kernels/reference.cpp
)
target_include_directories(KernelReference PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/kernels")
target_compile_options(KernelReference PRIVATE
  -O1
  -fno-vectorize
  -fno-slp-vectorize
  -ffp-contract=off
  -fno-fast-math
)
if(APPLE AND CMAKE_SYSTEM_PROCESSOR MATCHES "^(arm64|aarch64)$")
  target_compile_options(KernelReference PRIVATE -mcpu=apple-m1)
endif()

set(KERNEL_SOURCES
  kernels/saxpy.cpp
  kernels/dot.cpp
  kernels/stencil.cpp
)

foreach(LEVEL IN ITEMS 2 3)
  add_executable(kernel-correctness-O${LEVEL}
    tests/kernel_correctness.cpp
    ${KERNEL_SOURCES}
    $<TARGET_OBJECTS:KernelReference>
  )
  target_include_directories(kernel-correctness-O${LEVEL} PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}/kernels"
  )
  target_compile_options(kernel-correctness-O${LEVEL} PRIVATE
    -O${LEVEL}
    -fno-fast-math
  )
  if(APPLE AND CMAKE_SYSTEM_PROCESSOR MATCHES "^(arm64|aarch64)$")
    target_compile_options(kernel-correctness-O${LEVEL} PRIVATE -mcpu=apple-m1)
  endif()
endforeach()

if(BUILD_TESTING)
  add_test(NAME kernel-access-report
    COMMAND "${Python3_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/tests/run_tests.py"
      --opt "${OPT_EXECUTABLE}"
      --filecheck "${FILECHECK_EXECUTABLE}"
      --llvm-diff "${LLVM_DIFF_EXECUTABLE}"
      --plugin "$<TARGET_FILE:KernelAccessReport>"
      --tests "${CMAKE_CURRENT_SOURCE_DIR}/tests/lit"
  )

  add_test(NAME kernel-correctness-O2 COMMAND kernel-correctness-O2)
  add_test(NAME kernel-correctness-O3 COMMAND kernel-correctness-O3)
endif()

if(APPLE AND CMAKE_SYSTEM_PROCESSOR MATCHES "^(arm64|aarch64)$")
  set(M2_ARTIFACTS_DIR
    "${CMAKE_CURRENT_SOURCE_DIR}/artifacts/m2/llvm-23.1.6-apple-m1")
  set(M2_SMOKE_ARTIFACTS_DIR
    "${CMAKE_CURRENT_BINARY_DIR}/m2-baseline-smoke")

  add_custom_target(m2-baselines
    COMMAND "${Python3_EXECUTABLE}"
      "${CMAKE_CURRENT_SOURCE_DIR}/tools/generate_baselines.py"
      --clang "${CMAKE_CXX_COMPILER}"
      --opt "${OPT_EXECUTABLE}"
      --plugin "$<TARGET_FILE:KernelAccessReport>"
      --cpu apple-m1
      --output-dir "${M2_ARTIFACTS_DIR}"
    DEPENDS KernelAccessReport
    WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
    USES_TERMINAL
  )

  if(BUILD_TESTING)
    add_test(NAME m2-baseline-artifacts
      COMMAND "${Python3_EXECUTABLE}"
        "${CMAKE_CURRENT_SOURCE_DIR}/tools/generate_baselines.py"
        --clang "${CMAKE_CXX_COMPILER}"
        --opt "${OPT_EXECUTABLE}"
        --plugin "$<TARGET_FILE:KernelAccessReport>"
        --cpu apple-m1
        --output-dir "${M2_SMOKE_ARTIFACTS_DIR}"
    )
  endif()
endif()
