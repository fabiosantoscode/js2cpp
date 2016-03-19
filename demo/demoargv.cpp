#include "js2c.h"
#include <string>



int main (int argc, char* argv[]) {
    js2cpp_init_libuv();
    js2cpp_init_argv(argc, argv);
    console.log(std::string("process.argv.length:"), process.argv->length);
    console.log(std::string("process.argv:"), process.argv);
    js2cpp_run_libuv();
}
