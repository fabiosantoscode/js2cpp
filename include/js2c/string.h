
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
        return charAt(index);
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
        if (index < 0 || index >= length) { return String(""); }
        return substring(index, index + 1);
    }
    String substring(int indexStart, int indexEnd) const {
        std::string ret = "";
        if (indexStart < 0) indexStart = 0;
        if (indexEnd < 0) indexEnd = 0;
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

    static std::string get_std_string(const String& s) {
        return s.string_data;
    }
};


String typeof(double _) { return "number"; }
String typeof(int _) { return "number"; }
String typeof(String _) { return "string"; }
String typeof(std::function<void(void)>) { return "function"; }
String typeof(void* ptr) { return ptr != undefined ? "object" : "undefined"; }
