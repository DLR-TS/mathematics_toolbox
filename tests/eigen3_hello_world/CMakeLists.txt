cmake_minimum_required(VERSION 3.15)
project(eigen3_hello_world)

find_package(Eigen3 REQUIRED)
find_package(Catch2 REQUIRED)

add_executable(eigen3_hello_world eigen3_hello_world.cpp)

target_link_libraries(eigen3_hello_world PRIVATE Eigen3::Eigen)
