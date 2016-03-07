#include "js2c.h"
#include <string>



int main () {
    js2cpp_init_libuv();
    std::vector<double> x;
    x = std::vector<double>({ 1, 2 });
    console.log(x, std::vector<double>({ 1, 2 }), x[0], std::vector<double>({ 1, 2 })[0]);
    std::vector<std::string> y = std::vector<std::string>({ std::string("lel") });
    console.log(y, y[0]);
    js2cpp_run_libuv();
}
