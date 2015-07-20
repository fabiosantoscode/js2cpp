#include "stdio.h"
#include <string>

class Console {
    public:
    template<typename... Args>
    static void log(std::string first, Args... rest) {
        printf("%s ", first.c_str());
        log(rest...);
    }
    template<typename T, typename... Args>
    static void log(T t, Args... rest) {
        printf("%s ", std::to_string(t).c_str());
        log(rest...);
    }
    static void log(std::string only) {
        printf("%s\n", only.c_str());
    }
    template<typename T>
    static void log(T t) {
        printf("%s\n", std::to_string(t).c_str());
    }
};

class EmptyObject {};

class FKClass {
    public:
    FKClass(){}
};

Console console;
EmptyObject empty_object;

