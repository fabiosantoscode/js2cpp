#include "js2c.h"
#include <string>

struct FakeClass_0;

void _flatten_3 ();
void _flatten_2 ();
void _flatten_1 ();
void _flatten_0 ();
struct FakeClass_0 {
    
    FakeClass_0(){}
};



void _flatten_3 () {
    console.log(std::string("Called zeroth item in queue"));
}
void _flatten_2 () {
    console.log(std::string("Called second item in queue"));
}
void _flatten_1 () {
    console.log(std::string("Called first item in queue with"));
}
void _flatten_0 () {
}
int main (int argc, char* argv[]) {
    FakeClass_0 * _closure_0 = new FakeClass_0();
    js2cpp_init_libuv();
    js2cpp_init_argv(argc, argv);
    Array<std::function<void ()>> * queue = (new Array<std::function<void ()>>({ _flatten_0 }));
    queue->push(_flatten_1);
    queue->push(_flatten_2);
    queue->unshift(_flatten_3);
    while (queue->length) {
        queue->pop()();
    }
    js2cpp_run_libuv();
}
