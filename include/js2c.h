#include "stdio.h"
#include "math.h"
#include <string>
#include <vector>
#include <time.h>
#include <cstdlib>
#include <map>
#include <functional>
#include <iostream>
#include <iomanip>
#include <initializer_list>
#include "uv.h"
#define Infinity INFINITY
#define NaN NAN
// Temporary fix for how dumbjs transpiles commonJS modules.
// Should be done when there is an Undefinable<T> type.
#define undefined nullptr

struct Console;

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

template<typename T>
struct Array {
    friend Console;
    private:
    std::vector<T> vec;
    template<typename... Args>
    void from_arg_pack(T first, Args... rest) {
        from_arg_pack(first);
        from_arg_pack(rest...);
    }
    void from_arg_pack(T only) {
        push(only);
    }
    void from_arg_pack() { }
    public:
    double length;
    Array() {
        vec = std::vector<T>();
        length = 0;
    }
    Array(std::initializer_list<T> init) {
        vec = std::vector<T>();
        length = 0;
        for (auto iter = init.begin();
                iter != init.end();
                iter++) {
            push(*iter);
        }
    }
    Array(std::vector<T> & some_vec) {
        vec = some_vec;
        length = vec.size();
    }
    template<typename... Args>
    Array(Args... args) {
        length = 0;
        vec = std::vector<T>();
        from_arg_pack(args...);
    }
    T operator[] (double index) {
        int ind = index;
        if (ind < 0 || ind >= vec.size()) {
            return T();
        }
        return vec[ind];
    }
    double push(T value) {
        vec.push_back(value);
        length += 1;
        return length;
    }
    T pop() {
        length -= 1;
        T last_value = vec[length];
        vec.pop_back();
        return last_value;
    }
    double unshift(T value) {
        length += 1;
        vec.insert(vec.begin(), value);
        return length;
    }
    Array<T> * concat(Array<T> * other) {
        Array<T> *ret = new Array<T>();
        for (int i = 0; i < vec.size(); i++) {
            ret->push(vec[i]);
        }
        for (int i = 0; i < other->vec.size(); i++) {
            ret->push(other->vec[i]);
        }
        return ret;
    }
    double indexOf(T needle) {
        for (int i = 0; i < vec.size(); i++) {
            if (vec[i] == needle) {
                return i;
            }
        }
        return -1;
    }
};

#include "js2c/string.h"

template<typename TKey, typename TVal>
struct Map {
    friend Console;
    private:
    std::map<TKey, TVal> map;
    public:
    auto set(TKey key, TVal val) {
        map[key] = val;
        return this;
    }
    auto get(TKey key) {
        return map.at(key);
    }
    bool has(TKey key) {
        return map.find(key) != map.end();
    }
};

double Number(std::string convert_from) {
    if (convert_from.length() == 0) {
        return 0;
    }
    if (convert_from == "Infinity") {
        return INFINITY;
    }
    if (convert_from == "-Infinity") {
        return -INFINITY;
    }
    std::string to_parse = convert_from;
    int radix = 10;
    if (convert_from[0] == '0' && convert_from.length() >= 2) {
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
        to_parse = convert_from.substr(prefix_length);
    }
    for (int i = 0;
            i < to_parse.length();
            i++) {
        int c = to_parse[i];
        if (
            !(
                (radix >= 10 && c >= '0' && c <= '9') ||
                (radix == 8  && c >= '0' && c <= '7') ||
                (radix == 2  && c >= '0' && c <= '1') ||
                (radix == 16 && c >= 'a' && c <= 'f') ||
                (radix == 16 && c >= 'A' && c <= 'F') ||
                (c == ' ' || c == '\t' || c == '\r' || c == '\n' || c == '\f')
            )
        ) {
            return NaN;
        }
    }
    if (radix != 10) {
        return dumbjs_number_convert::parse(to_parse, radix);
    }
    return strtod(to_parse.c_str(), NULL);
}

double Number(String convert_from) {
    return Number(String::get_std_string(convert_from));
}
double Number(nullptr_t) { return 0; }
double Number() { return 0; }
double Number(double n) { return n; }

bool isNaN(auto n) { return isnan(Number(n)); }
bool isNaN(double n) { return isnan(n); }
bool isNaN(nullptr_t) { return true; }
bool isNaN() { return true; }

struct Math_ {
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
    double imul(double a, double b) { return ((int)a) * ((int)b); }
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

#include "js2c/console.h"

Console console;

#include "js2c/process.h"

void js2cpp_init_argv(int argc, char* argv[]) {
    process.argv = new Array<String>();
    // Put something in process.argv[0], so that the user's application may be the second argument.
    // since node scripts expect their arguments to start with the node runtime and then just read arguments from argv[2] on
    // that means something has to be here.
    //
    // TODO in the future create js2cpp-node command so it may be the first argument,
    // and the javascript file that generated the program, the second argument.
    process.argv->push(String("/usr/bin/env"));
    for (int i = 0; i < argc; i++) {
        process.argv->push(String(argv[i]));
    }
}
