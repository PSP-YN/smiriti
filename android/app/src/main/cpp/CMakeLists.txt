cmake_minimum_required(VERSION 3.22.1)
project(smriti_llama)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find Android NDK libraries
find_library(ANDROID_LOG log)

# llama.cpp configuration
# In production, llama.cpp source should be included as a submodule
# or pre-built libraries should be provided

# Option 1: Using pre-built llama.cpp libraries
# These would be placed in jniLibs directory

# Option 2: Building llama.cpp from source (requires submodule)
# add_subdirectory(llama.cpp)

# For Week 3/4, we'll create a stub that simulates the FFI interface
# In production, replace with actual llama.cpp build

add_library(
    llama
    SHARED
    llama_bridge.cpp
)

target_link_libraries(
    llama
    ${ANDROID_LOG}
)

# Compiler optimizations for LLM inference
target_compile_options(llama PRIVATE
    -O3
    -DNDEBUG
    -fvisibility=hidden
    -ffunction-sections
    -fdata-sections
)

# Link-time optimization
target_link_options(llama PRIVATE
    -Wl,--gc-sections
    -Wl,-O3
)
