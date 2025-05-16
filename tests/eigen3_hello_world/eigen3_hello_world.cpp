#define CATCH_CONFIG_MAIN
#define CATCH_CONFIG_PRINT_EXPRESSIONS // Enable printing REQUIRE statements

#include <iostream>
#include <Eigen/Dense>
#include <catch2/catch.hpp>

using Eigen::MatrixXd;
 
TEST_CASE("Simple integration"){
  MatrixXd m(2,2);
  m(0,0) = 3;
  m(1,0) = 2.5;
  m(0,1) = -1;
  m(1,1) = m(1,0) + m(0,1);
  REQUIRE(m(1,1) == 1.5);
}
