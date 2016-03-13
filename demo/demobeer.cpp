#include "js2c.h"
#include <string>



int main () {
    js2cpp_init_libuv();
    for (double i = 99; i > 0; i--) {
        double j = i - 1;
        std::string icase;
        std::string jcase;
        if (i != 1) {
            icase = std::string("bottles");
        } else {
            icase = std::string("bottle");
        }
        if (j != 1) {
            jcase = std::string("bottles");
        } else {
            jcase = std::string("bottle");
        }
        console.log(String(i) + std::string(" ") + icase + std::string(" of beer on the wall,"));
        console.log(String(i) + std::string(" ") + icase + std::string(" of beer,"));
        console.log(std::string("Take 1 down, pass it around,"));
        if (j != 0) {
            console.log(String(j) + std::string(" ") + jcase + std::string(" of beer on the wall."));
        } else {
            console.log(std::string("No more bottles of beer on the wall!"));
        }
    }
    js2cpp_run_libuv();
}
