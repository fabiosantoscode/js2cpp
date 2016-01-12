#include "stdio.h"
#include "math.h"
#include <string>
#include <vector>
#include <time.h>
#include <cstdlib>
#include <functional>
#include <algorithm>
#include <sstream>
#include <iostream>
#include <iomanip>
#define NaN NAN
#define isNaN isnan
// Temporary fix for how dumbjs transpiles commonJS modules.
// Should be done when there is an Undefinable<T> type.
#define undefined nullptr

namespace dumbjs_number_convert {
    double parse(std::string n, int base) {
        return (double) strtol(n.c_str(), NULL, base);
    }
    std::string stringify(double n, int base) {
        if (isnan(n)) {
            return std::string("NaN");
        }
        if (n == (int) n) {
            return std::to_string((int) n);
        }
        std::ostringstream stream;
        stream << std::fixed << std::setprecision(15) << n;
        return stream.str();
    }
};

std::string String (double);

template<typename T>
std::string String(std::vector<T> ary) {
    std::string s("");
    size_t len = ary.size();
    for (size_t i = 0; i < len; i++) {
        s += String(ary[i]);
        if (i < len - 1)
            s += std::string(",");
    }
    return s;
}

std::string String (double convert_from) {
    return dumbjs_number_convert::stringify(convert_from, 10);
}

std::string String (std::nullptr_t x) {
    // Temporary fix for how commonJS modules are transpiled
    return std::string("undefined");
}

std::string String (std::string convert_from) {
    return convert_from;
}


std::string String() { return std::string(""); }

double Number(std::string convert_from) {
    if (convert_from.length() == 0) {
        return 0;
    }
    if (convert_from[0] == ' ') {
        return Number(convert_from.substr(1));
    }
    if (convert_from[0] == '0' && convert_from.length() >= 2) {
        int radix;
        int prefix_length;
        switch (convert_from[1]) {
            case 'x':
            case 'X':
                radix = 16;
                prefix_length = 2;
            break;
            case 'o':
            case 'O':
                radix =  8;
                prefix_length = 2;
            break;
            case 'B':
            case 'b':
                radix =  2;
                prefix_length = 2;
            break;
            default:
                radix = 10;
                prefix_length = 1;
            break;
        }
        return dumbjs_number_convert::parse(convert_from.substr(prefix_length), radix);
    }
    return strtod(convert_from.c_str(), NULL);
}

double Number() { return 0; }

double Number(double n) { return n; }

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

class Env {
    public:
    std::string operator [] (std::string variable) {
        try {
            return std::getenv(variable.c_str());
        } catch (std::logic_error e) {
            return std::string("");
        }
    }
    std::string setenv (std::string variable, std::string value) {
        ::setenv(variable.c_str(), value.c_str(), value.length());
        return value;
    }
};

class Process {
    public:
    Env env;
};

Process process;

class Console {
    template<typename T>
    static std::string representation(std::vector<T> only) {
        std::string s("[ ");
        for (typename std::vector<T>::iterator iter = only.begin();
                iter != only.end();
                iter++) {
            s += representation(*iter);
            if (iter != only.end() - 1) { s += std::string(", "); }
        }
        s += (" ]");
        return s;
    }
    static std::string representation(double n) {
        if (n == (int) n) {
            return std::to_string((int) n);
        }
        if (isnan(n)) {
            return std::string("NaN");
        }
        return std::to_string(n);  // Cuts to 6 zeroes, just like node does when printing to the console
    }
    static std::string representation(int boolean_value) {
        return std::string(
            boolean_value ? "true" : "false"
        );
    }
    static std::string representation(std::string only) {
        return only;
    }
    public:
    template<typename T>
    static void log(T only) {
        std::cout << representation(only) << std::endl;
    }
    template<typename T, typename... Args>
    static void log(T first, Args... rest) {
        std::cout << representation(first) << std::string(" ");
        log(rest...);
    }
};

Console console;

