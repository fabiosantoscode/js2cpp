#include "js2c.h"
#include <string>

struct FakeClass_0:public FKClass {
    double y;
    std::string z;
    FakeClass_0(){}
    FakeClass_0(EmptyObject _){}
};



int main () {
    FakeClass_0 * x = new FakeClass_0();
    x->y = -1;
    x->z = std::string("Hello c++!");
    console.log(x->z, x->y);
}
