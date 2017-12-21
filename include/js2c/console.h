
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
        if (n == (int) n)
            return std::to_string((int) n);
        if (isnan(n))
            return std::string("NaN");
        if (n == Infinity)
            return std::string("Infinity");
        if (n == -Infinity)
            return std::string("-Infinity");
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
