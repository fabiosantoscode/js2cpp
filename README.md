

# What's this?

It's the product of the crazy idea of using the very excellent tern.js project to figure out the types of things and use them!

js2cpp a toy thing. Do not use it!

Lel.

# How can I use it?

Yeah, it actually does some things. Here's a simple "return 0" program:

    $ echo 'function main(argc, argv) { return 0 }' | coffee bin/js2cpp
    #include "js2c.h"
    #include <string>
    
    int main () {
        return 0;
    }

This is the only way you get to see an "int" though. js2cpp knows that the function named "main" MUST return "int" instead of "double". If you don't add any return statements it will be "void" instead, which might compile somewhere, who knows.

This is how js2cpp handles strings:

    $ echo '"lol" + "lel"' | coffee bin/js2cpp
    #include "js2c.h"
    #include <string>

    std::string("lol") + std::string("lel");

And here's console.log!

    $ echo 'console.log(1,2,3)' | coffee bin/js2cpp
    #include "js2c.h"
    #include <string>
    
    console.log(1, 2, 3);

It works because there's a "console" instance of a "Console" class with a variadic "log" function.

Here is tern.js figuring out a couple of types. Just don't touch arrays because I'm lazy.

    $ echo 'var aNumber = 1; var aString = "1";' | coffee bin/js2cpp
    #include "js2c.h"
    #include <string>
    
    double aNumber = 1;
    std::string aString = std::string("1");


# Hey this is AMAZING I WANNA FORK IT SELL IT OR WHATEVER WHAT IS TEH LICENSSSS

Just have fun with it! WTFPL

