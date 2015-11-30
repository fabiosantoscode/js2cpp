#include "stdio.h"
#include <string>
#include <functional>

class Console {
    public:
    template<typename... Args>
    static void log(std::string first, Args... rest) {
        printf("%s ", first.c_str());
        log(rest...);
    }
    template<typename... Args>
    static void log(double first, Args... rest) {
        if (first == (int)first) {
            printf("%0.0f ", first);
        } else {
            printf("%f ", first);
        }
        log(rest...);
    }
    static void log(std::string only) {
        printf("%s\n", only.c_str());
    }
    static void log(double only) {
        if (only == (int)only) {
            printf("%0.0f\n", only);
        } else {
            printf("%f\n", only);
        }
    }
};

Console console;

