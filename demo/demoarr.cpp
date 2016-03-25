#include "js2c.h"
#include <string>





int main (int argc, char* argv[]) {
    js2cpp_init_libuv();
    js2cpp_init_argv(argc, argv);
    Array<double> * x;
    x = (new Array<double>({ 1.0f, 2.0f }));
    console.log(x, (new Array<double>({ 1.0f, 2.0f })), (*x)[0.0f], (*(new Array<double>({ 1.0f, 2.0f })))[0.0f]);
    Array<std::string> * y = (new Array<std::string>({ std::string("lel") }));
    console.log(y, (*y)[0.0f]);
    y->push(std::string("foo"));
    console.log(y);
    js2cpp_run_libuv();
}
