cmake_minimum_required(VERSION 3.15)
project(osqp_hello_world)

set(CMAKE_CXX_FLAGS "-std=c++17 -Wall -Wextra -O3")


find_package(osqp REQUIRED)

add_executable(osqp_hello_world osqp_hello_world.cpp)
target_compile_options(osqp_hello_world PRIVATE -fpermissive)

target_link_libraries(osqp_hello_world PRIVATE osqp::osqp)
