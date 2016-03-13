#include "js2c.h"
#include <string>

struct FakeClass_0 {
    double start;
    FakeClass_0(){}
};


struct _flatten_incrementor {
    FakeClass_0 * _closure;
    _flatten_incrementor(FakeClass_0 * _closure):_closure(_closure) { }
    double operator() ();
};
struct _flatten_incrementor;
struct _flatten_demo;
struct FakeClass_1 {
    _flatten_demo * demo;
    std::function<_flatten_incrementor * (double)> inc;
    FakeClass_1(){}
};


struct _flatten_demo {
    FakeClass_1 * _closure;
    _flatten_demo(FakeClass_1 * _closure):_closure(_closure) { }
    void operator() ();
};
_flatten_incrementor * _flatten_inc (double start);

double _flatten_incrementor::operator() () {
    return _closure->start++;
}
void _flatten_demo::operator() () {
    _flatten_incrementor * inc0 = _closure->inc(0);
    console.log((*inc0)());
    console.log((*inc0)());
    console.log((*inc0)());
}
_flatten_incrementor * _flatten_inc (double start) {
    FakeClass_0 * _closure_1 = new FakeClass_0();
    _closure_1->start = start;
    return new _flatten_incrementor(_closure_1);
}
int main () {
    FakeClass_1 * _closure_0 = new FakeClass_1();
    _closure_0->inc = _flatten_inc;
    _closure_0->demo = new _flatten_demo(_closure_0);
    js2cpp_init_libuv();
    (*_closure_0->demo)();
    js2cpp_run_libuv();
}
