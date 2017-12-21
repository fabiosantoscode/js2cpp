
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
