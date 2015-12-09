#include "js2c.h"
#include <string>

struct FakeClass_0 {
    double start;
    FakeClass_0(){}
};


struct _flatten_2;
struct _flatten_0;
struct FakeClass_1 {
    _flatten_2 * demo;
    std::function<_flatten_0 * (double)> inc;
    FakeClass_1(){}
};



struct _flatten_0 {
    FakeClass_0 * _closure;
    _flatten_0(FakeClass_0 * _closure):_closure(_closure) { }
    double operator() () {
        return _closure->start++;
    }
};
struct _flatten_2 {
    FakeClass_1 * _closure;
    _flatten_2(FakeClass_1 * _closure):_closure(_closure) { }
    void operator() () {
        _flatten_0 * inc0 = _closure->inc(0);
        console.log((*inc0)());
        console.log((*inc0)());
        console.log((*inc0)());
    }
};
_flatten_0 * _flatten_1 (double start) {
    FakeClass_0 * _closure_1 = new FakeClass_0();
    _closure_1->start = start;
    return new _flatten_0(_closure_1);
}
int main () {
    FakeClass_1 * _closure_0 = new FakeClass_1();
    _closure_0->inc = _flatten_1;
    _closure_0->demo = new _flatten_2(_closure_0);
    (*_closure_0->demo)();
}
