#include "stdio.h"
#include <string>
#include <vector>
#include <functional>

class Console {
    public:
    static void log(double only) {
        if (only == (int)only) {
            printf("%0.0f\n", only);
        } else {
            printf("%f\n", only);
        }
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
    template<typename... Args>
    static void log(std::string first, Args... rest) {
        printf("%s ", first.c_str());
        log(rest...);
    }
    static void log(std::vector<double> only) {
        printf("[ ");
        for (std::vector<double>::iterator iter = only.begin();
                iter != only.end();
                iter++) {
            if (*iter == (int)*iter) {
                printf("%0.0f", *iter);
            } else {
                printf("%f", *iter);
            }
            if (iter != only.end() - 1) { printf(", "); }
        }
        printf(" ]\n");
    }
    template <typename... Args>
    static void log(std::vector<double> only, Args... rest) {
        printf("[ ");
        for (std::vector<double>::iterator iter = only.begin();
                iter != only.end();
                iter++) {
            if (*iter == (int)*iter) {
                printf("%0.0f", *iter);
            } else {
                printf("%f", *iter);
            }
            if (iter != only.end() - 1) { printf(", "); }
        }
        printf(" ] ");
        log(rest...);
    }
};

Console console;

