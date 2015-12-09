#include "js2c.h"
#include <string>



int main () {
    std::vector<double> x;
    x = std::vector<double>({ 1, 2 });
    console.log(x, std::vector<double>({ 1, 2 }), x[0], std::vector<double>({ 1, 2 })[0]);
}
