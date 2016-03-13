#include "js2c.h"
#include <string>

struct FakeClass_0 {
    double y;
    std::string z;
    FakeClass_0(){}
};



int main () {
    js2cpp_init_libuv();
    FakeClass_0 * x = new FakeClass_0();
    x->y = -1;
    x->z = std::string("Hello c++!");
    console.log(x->z, x->y);
    js2cpp_run_libuv();
}
