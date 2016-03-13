#include "js2c.h"
#include <string>



int main () {
    js2cpp_init_libuv();
    Array<double> * x;
    x = (new Array<double>({ 1, 2 }));
    console.log(x, (new Array<double>({ 1, 2 })), (*x)[0], (*(new Array<double>({ 1, 2 })))[0]);
    Array<std::string> * y = (new Array<std::string>({ std::string("lel") }));
    console.log(y, (*y)[0]);
    y->push(std::string("foo"));
    console.log(y);
    js2cpp_run_libuv();
}
