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
#define NaN NAN
#define isNaN isnan
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
    double indexOf(T needle) {
        for (int i = 0; i < vec.size(); i++) {
            if (vec[i] == needle) {
                return i;
            }
        }
        return -1;
    }
};

struct String {
    friend Console;
    private:
    std::string string_data;
    inline void set_string_data(std::string s) {
        string_data = s;
        length = s.length();
    }
    public:
    double length;

    String (double convert_from) {
        set_string_data(dumbjs_number_convert::stringify(convert_from, 10));
    }

    String (std::nullptr_t x) {
        // Temporary fix for how commonJS modules are transpiled
        set_string_data(String("undefined"));
    }

    String (const char *convert_from) {
        set_string_data(convert_from);
    }

    String (const std::string & convert_from) {
        set_string_data(convert_from);
    }

    String() {
        set_string_data(String(""));
    }

    operator std::string() {
        return string_data;
    }

    String operator[] (int index) const {
        std::string ret = "";
        ret += string_data[index];
        return ret;
    }

    String operator+ (const std::string &other) const {
        return this->string_data + other;
    }

    String operator+= (const std::string &other) {
        set_string_data(string_data + other);
        return string_data;
    }

    bool operator == (const std::string &other) const {
        return string_data == other;
    }

    bool operator != (const std::string &other) const {
        return string_data != other;
    }

    template<typename T>
    String(Array<T> *ary) {
        std::string s("");
        size_t len = ary->length;
        for (size_t i = 0; i < len; i++) {
            s += String((*ary)[i]);
            if (i < len - 1)
                s += std::string(",");
        }
        set_string_data(s);
    }

    String charAt(int index) const {
        if (index > length || index < 0) { return ""; }
        return this[index];
    }
    String substring(int indexStart, int indexEnd) const {
        std::string ret = "";
        if (indexStart < 0 || isnan(indexStart)) indexStart = 0;
        if (indexEnd < 0 || isnan(indexEnd)) indexEnd = 0;
        if (indexStart > length) indexStart = length;
        if (indexEnd > length) indexEnd = length;
        if (indexStart > indexEnd) {
            std::swap(indexStart, indexEnd);
        }
        for (int i = indexStart; i < indexEnd; i++)
            ret += string_data[i];
        return ret;
    }
    String substring(int indexStart) const {
        return substring(indexStart, length);
    }
    String substr(int indexStart, int len) const {
        if (indexStart < 0) { indexStart += length; }
        if (len < 0) { return String(""); }
        return substring(indexStart, indexStart + len);
    }
    String substr(int indexStart) const {
        return substr(indexStart, length - indexStart);
    }
    String concat(const String &other) const {
        return string_data + other.string_data;
    }
    Array<String> * split() const {
        return new Array<String>({ String(*this) });
    }
    Array<String> * split(const String &split_by, int limit = -1) const {
        auto ret = new Array<String>();
        if (split_by.length > length) {
            if (limit == 0) { return ret; }
            ret->push(*this);
            return ret;
        }
        if (split_by.length == 0) {
            std::string this_string = "";
            for (int i = 0; i < length; i++) {
                this_string += string_data[i];
                if (limit >= 0 && ret->length >= limit) { return ret; }
                ret->push(this_string);
                this_string = "";
            }
            return ret;
        }
        int match_i = 0;
        int i = 0;
        bool matching_substring = false;
        std::string this_split = "";
        while (i < length) {
            if (matching_substring == false) {
                if (split_by.string_data[0] == string_data[i]) {
                    matching_substring = true;
                    match_i = 1;
                    ret->push(this_split);
                    if (limit >= 0 && ret->length >= limit) { return ret; }
                    this_split = "";
                } else {
                    this_split += string_data[i];
                }
            } else {
                if (split_by.string_data[match_i] != string_data[i]) {
                    matching_substring = false;
                    this_split = "";
                    this_split += string_data[i];
                } else {
                    ;  // Consume string
                }
                match_i++;
            }
            i++;
        }
        ret->push(this_split);
        return ret;
    }
};


String typeof(double _) { return "number"; }
String typeof(int _) { return "number"; }
String typeof(String _) { return "string"; }
String typeof(std::function<void(void)>) { return "function"; }
String typeof(void* ptr) { return ptr != undefined ? "object" : "undefined"; }

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

struct Console {
    private:
    template<typename T>
    static std::string representation(Array<T> *only) {
        return representation(*only);
    }
    template<typename T>
    static std::string representation(Array<T> only) {
        if (only.length == 0) {
            return "[]";
        }
        std::string s("[ ");
        for (auto iter = only.vec.begin();
                iter != only.vec.end();
                iter++) {
            if (iter != only.vec.begin()) { s += ", "; }
            s += long_representation(*iter);
        }
        s += (" ]");
        return s;
    }
    template<typename TKey, typename TVal>
    static std::string representation(Map<TKey, TVal> *only) {
        return representation(*only);
    }
    template<typename TKey, typename TVal>
    static std::string representation(Map<TKey, TVal> only) {
        std::string s("Map { ");
        for (auto iter = only.map.begin();
                iter != only.map.end();
                iter++) {
            if (iter != only.map.begin()) { s += ", "; }
            s += representation(iter->first);
            s += " => ";
            s += representation(iter->second);
        }
        s += " }";
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
    static std::string representation(void* only) {
        if (only == undefined) {
            return "undefined";
        }
        return std::string("[Object]");
    }
    static std::string representation(std::function<void(void)>any) {
        return std::string("[Function]");
    }
    static std::string long_representation(std::string a_string) {
        std::string out = std::string("'");
        for (auto iter = a_string.begin();
                iter != a_string.end();
                iter++) {
            bool should_escape =
                *iter == '\n' ||
                *iter == '\r' ||
                *iter == '\\' ||
                *iter == '\'' ||
                *iter == '\0';

            if (should_escape) {
                out += std::string("\\");
            }
            out.append(1, *iter);
        }
        out += std::string("'");
        return out;
    }
    static std::string long_representation(String the_string) {
        return long_representation(std::string(the_string));
    }
    static std::string long_representation(auto whatever) {
        return representation(whatever);
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

// Libuv integration
void on_timeout_end(uv_timer_t*);
void clearTimeout(double);
namespace Js2cppLibuv {
    uv_loop_t* loop;
    std::map<uv_timer_t*, std::function<void (void)>> timeouts;
    std::map<double, uv_timer_t*> opaque_handles;
    std::map<uv_timer_t*, double> timer_to_opaque_handle;
    double last_opaque_handle = 1;
    void remove(double opaque_handle) {
        auto timer = opaque_handles[opaque_handle];
        if (timer == NULL) return;
        uv_timer_stop(timer);
        timeouts.erase(timer);
        opaque_handles.erase(opaque_handle);
        timer_to_opaque_handle.erase(timer);
    }
    void remove(uv_timer_t* timer) {
        remove(timer_to_opaque_handle[timer]);
    }
    void timeout_end(uv_timer_t* timer) {
        auto cb = timeouts[timer];
        if (cb == NULL) return;
        cb();
    }
    double add(std::function<void (void)> func, int timeout_time, bool is_interval = false) {
        uv_timer_t *timer = (uv_timer_t*)malloc(sizeof(uv_timer_t));
        uv_timer_init(loop, timer);
        timeouts[timer] = func;
        opaque_handles[++last_opaque_handle] = timer;
        if (!is_interval) {
            uv_timer_start(timer, timeout_end, timeout_time, 0);
        } else {
            if (timeout_time < 1) timeout_time = 1;
            uv_timer_start(timer, timeout_end, timeout_time, timeout_time);
        }
        return last_opaque_handle;
    }
    void init() {
        loop = (uv_loop_t*)malloc(sizeof(uv_loop_t));
        uv_loop_init(loop);
    }
    void run() {
        uv_run(loop, UV_RUN_DEFAULT);
    }
};
void js2cpp_init_libuv() { Js2cppLibuv::init(); };
void js2cpp_run_libuv() { Js2cppLibuv::run(); };


double setTimeout(auto func, int timeout_time = 0) {
    return Js2cppLibuv::add(func, timeout_time);
}
void clearTimeout(double opaque_handle) {
    Js2cppLibuv::remove(opaque_handle);
}


double setInterval(auto func, int timeout_time = 0) {
    return Js2cppLibuv::add(func, timeout_time, /*is_interval=*/true);
}
void clearInterval(double opaque_handle) {
    Js2cppLibuv::remove(opaque_handle);
}


double setImmediate(auto func) {
    return Js2cppLibuv::add(func, 0);
}
void clearImmediate(double opaque_handle) {
    Js2cppLibuv::remove(opaque_handle);
}


// Node things
struct Env {
    String operator [] (String variable) {
        try {
            return std::getenv(std::string(variable).c_str());
        } catch (std::logic_error e) {
            return String("");
        }
    }
    String setenv (std::string variable, std::string value) {
        ::setenv(variable.c_str(), value.c_str(), value.length());
        return value;
    }
};

struct Process {
    Env env;
    Array<String> * argv;
    void nextTick(auto func) {
        setImmediate(func);  /* Handle remains hidden */
    }
    void exit(int exit_code = 0) {
        ::exit(exit_code);
    }
};

Process process;

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
