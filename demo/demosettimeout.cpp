#include "js2c.h"
#include <string>

struct FakeClass_0 {
    double count;
    double interval;
    FakeClass_0(){}
};


struct _flatten_4 {
    FakeClass_0 * _closure;
    _flatten_4(FakeClass_0 * _closure):_closure(_closure) { }
    void operator() ();
};
void _flatten_3 ();
void _flatten_2 ();
struct FakeClass_1 {
    std::function<void ()> proceed;
    double thatWhichShallNotBeRun;
    double thatWhichShallNotBeRun2;
    FakeClass_1(){}
};


struct FakeClass_2 {
    FakeClass_1 * _closure_0;
    FakeClass_2(){}
};


struct _flatten_1 {
    FakeClass_1 * _closure;
    _flatten_1(FakeClass_1 * _closure):_closure(_closure) { }
    void operator() ();
};
struct _flatten_0 {
    FakeClass_2 * _closure;
    _flatten_0(FakeClass_2 * _closure):_closure(_closure) { }
    void operator() ();
};
void _flatten_proceed ();

void _flatten_4::operator() () {
    console.log(_closure->count);
    if (!--_closure->count)
        clearInterval(_closure->interval);
}
void _flatten_3 () {
    console.log(std::string("fifteen!"));
}
void _flatten_2 () {
    console.log(std::string("fifteen!"));
}
void _flatten_1::operator() () {
    FakeClass_2 * _closure_1 = new FakeClass_2();
    _closure_1->_closure_0 = _closure;
    console.log(std::string("two"));
    clearTimeout(_closure->thatWhichShallNotBeRun);
    clearImmediate(_closure->thatWhichShallNotBeRun2);
    setTimeout(new _flatten_0(_closure_1), 500);
}
void _flatten_0::operator() () {
    console.log(std::string("three"));
    _closure->_closure_0->proceed();
}
void _flatten_proceed () {
    FakeClass_0 * _closure_2 = new FakeClass_0();
    _closure_2->count = 3;
    _closure_2->interval = setInterval(new _flatten_4(_closure_2), 1000);
    console.log(std::string("counting down using interval number"), _closure_2->interval);
}
int main () {
    FakeClass_1 * _closure_0 = new FakeClass_1();
    _closure_0->proceed = _flatten_proceed;
    js2cpp_init_libuv();
    process.nextTick(new _flatten_1(_closure_0));
    console.log(std::string("one"));
    _closure_0->thatWhichShallNotBeRun = setTimeout(_flatten_2);
    _closure_0->thatWhichShallNotBeRun2 = setImmediate(_flatten_3);
    js2cpp_run_libuv();
}
