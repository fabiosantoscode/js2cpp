#include "js2c.h"
#include <string>



int main () {
    js2cpp_init_libuv();
    console.log(std::string("Math.floor(Math.PI * 100) / 100:"), Math.floor(Math.PI * 100) / 100);
    console.log(std::string("Math.imul(3, 2):"), Math.imul(3, 2));
    console.log(std::string("Math.pow(2, 10):"), Math.pow(2, 10));
    console.log(std::string("Math.log(Math.E):"), Math.log(Math.E));
    console.log(std::string("Math.ceil(Math.LOG10E):"), Math.ceil(Math.LOG10E));
    console.log(std::string("Math.sin(90):"), Math.sin(90));
    console.log(std::string("Math.sqrt(4):"), Math.sqrt(4));
    console.log(std::string("Math.tan(45):"), Math.tan(45));
    console.log(std::string("Math.trunc(2.000001):"), Math.trunc(2.000001));
    console.log(std::string("Math.max(1):"), Math.max(1));
    console.log(std::string("Math.max(1, 2):"), Math.max(1, 2));
    console.log(std::string("Math.max(1, 2, -1):"), Math.max(1, 2, -1));
    console.log(std::string("Math.max(1):"), Math.max(1));
    console.log(std::string("Math.max(1, 2):"), Math.max(1, 2));
    console.log(std::string("Math.max(1, 2, -1):"), Math.max(1, 2, -1));
    console.log(std::string("Math.random() != Math.random()"), Math.random() != Math.random());
    console.log(std::string("Math.random() <= 1 && Math.random() >= 0"), Math.random() <= 1 && Math.random() >= 0);
    console.log(std::string("NaN"), NaN);
    console.log(std::string("isNaN(NaN)"), isNaN(NaN));
    js2cpp_run_libuv();
}
