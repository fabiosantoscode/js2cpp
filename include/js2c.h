#include "stdio.h"
#include "math.h"
#include <string>
#include <vector>
#include <time.h>
#include <functional>
#define NaN NAN
#define isNaN isnan

class Math_ {
    public:
    Math_() {
        struct timespec ts;
        clock_gettime(CLOCK_MONOTONIC, &ts);
        srand(ts.tv_sec + ts.tv_nsec);
    }
    double E       = 2.718281828459045;
    double LN10    = 2.302585092994046;
    double LN2     = 0.6931471805599453;
    double LOG10E  = 0.4342944819032518;
    double LOG2E   = 1.4426950408889634;
    double PI      = 3.141592653589793;
    double SQRT1_2 = 0.7071067811865476;
    double SQRT_2  = 1.4142135623730951;
    double abs(double n) { return ::abs(n); }
    double acos(double n) { return ::acos(n); }
    // double acosh(double n) { return }
    double asin(double n) { return ::asin(n); }
    // double asinh (double n) { return }
    double atan(double n) { return ::atan(n); }
    // double atan2(double n) { return  }
    // double atanh(double n) { return }
    // double cbrt(double n) { return }
    double ceil(double n) { return ::ceil(n); }
    // double clz32(double n) { return }
    double cos(double n) { return ::cos(n); }
    // double cosh(double n) { return }
    double exp(double n) { return ::exp(n); }
    // double expm1(double n) { return }
    double floor(double n) { return ::floor(n); }
    // double fround(double n) { return }
    // double hypot(double n) { return }
    double imul(double a, double b) { return a * b; }
    double log(double n) { return ::log(n); }
    // double log10(double n) { return }
    // double log1p(double n) { return }
    // double log2(double n) { return }
    double pow(double n, double power) { return ::pow(n, power); }
    double random() { return (double)rand() / RAND_MAX; }
    double round(double n) { return ::round(n); }
    // double sign(double n) { return }
    double sin(double n) { return ::sin(n); }
    // double sinh(double n) { return }
    double sqrt(double n) { return ::sqrt(n); }
    double tan(double n) { return ::tan(n); }
    // double tanh(double n) { return }
    double trunc(double n) { return (int) n; }
    template<typename... Args>
    double max(double n, Args... rest) {
        double tmp = max(rest...);
        if (n > tmp) {
            return n;
        } else {
            return tmp;
        }
    }
    double max(double n) {
        return n;
    }
    template<typename... Args>
    double min(double n, Args... rest) {
        double tmp = min(rest...);
        if (n < tmp) {
            return n;
        } else {
            return tmp;
        }
    }
    double min(double n) {
        return n;
    }
};

Math_ Math;

class Console {
    public:
    static void log(int only) {
        printf("%s\n", only ? "true" : "false");
    }
    template<typename... Args>
    static void log(int first, Args... rest) {
        printf("%s ", first ? "true" : "false");
        log(rest...);
    }
    static void log(double only) {
        if (isnan(only)) {
            printf("NaN\n");
        } else if (only == (int)only) {
            printf("%0.0f\n", only);
        } else {
            printf("%f\n", only);
        }
    }
    template<typename... Args>
    static void log(double first, Args... rest) {
        if (isnan(first)) {
            printf("NaN ");
        } else if (first == (int)first) {
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

