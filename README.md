[![Build Status](https://travis-ci.org/fabiosantoscode/js2cpp.svg?branch=master)](https://travis-ci.org/fabiosantoscode/js2cpp)

# What's this?

It's the product of the crazy idea of using the very excellent tern.js project to figure out the types of things and use them!

js2cpp should be usable some day. For now you can do crazy experiments on it :)

# How can I use it?

Yeah, it actually does some things. This is how js2cpp handles strings:

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

Here is tern.js figuring out a couple of types.

    $ echo 'var aNumber = 1; var aString = "1";' | coffee bin/js2cpp
    #include "js2c.h"
    #include <string>
    
    double aNumber = 1;
    std::string aString = std::string("1");

# How do I run this?

 * First, you need to update your compiler to a version that supports C++14. If you're using gcc, make sure you have g++ 5. Get it from brew or linuxbrew, don't ruin your machine by adding another compiler globally! I've been there.
 * Then, clone this repo and run `npm install`
 * Afterwards, you need to fetch and compile libuv. run `bash scripts/get-libuv.sh`. This *seems* to run on linux machines. If not, clone libuv into `deps/libuv`, compile it, and copy `libuv.a` into `deps`.
 * Optionally `npm test` just to make sure it works on your machine ;) If it doesn't please make an issue about it and I'll try to look into it. It tries to use the `g++` binary from your PATH. If you want to use another binary specify it with the `GPP_BINARY` environment variable, like so: `GPP_BINARY=g++-5 npm test`.
 * To compile some javascript, run `./bin/js2cpp < your-javascript.js > your-cee-plus-plus.cpp`. You may need coffeescript for this because I'm lazy!
 * Then compile your cpp file. (example with g++) `g++ -std=c++14 your-cee-plus-plus.cpp -Wall -Werror -O3 -I include/ -lrt`
 * Then run `./a.out` to run your program.

# Dumbjs

js2cpp is kind of a frontend to fabiosantoscode/dumbjs, a javascript simplifier. It turns javascript that looks like this:

```
function foo(x) {
    x++
    return function () { return x }
}
console.log(foo(0)())
```

Into something like this:

```
var _flatten_0 = function (_closure) {
    return _closure.x
}
var foo = function (x) {
    var _closure_0 = {}
    _closure_0.x = x
    _closure_0.x++
    return BIND(_flatten_0, _closure_0)
}
var main = function () {
    console.log(foo(0)())
}
```
(the BIND function must be defined elsewhere, in this case in js2cpp)

Its features are closure simulation, main-ification (put stuff in a main() function), function de-nesting, and more will come.

Since all of it is a much simpler form of javascript, it takes off a huge weight off the shoulders of js2cpp and makes sure its code remains (somewhat) understandable by not mixing up concerns.

This also means that you can use dumbjs to transpile javascript to other languages. Most of its features are switchable, because not every transpilation target language will need you to do things like wrapping things in a main() function or simulating closures.


# Roadmap

(unordered)

The main objective of this project is to implement at least 80% of the parts of javascript you use every day.

This means that, like a lot of npm modules which accidentally work in the browser when browserified, a lot of npm modules should accidentally work natively when js2cpp-ified.

All of the following features may be implemented in dumbjs, in this project, or in both at the same time, depending on whether they apply to each project.

 - Plug in the [http://www.hboehm.info/gc/](Boehm-Demers-Weiser conservative garbage collector) (which works in C and C++, it seems!)
 - Rewrite this and dumbjs in pure javascript
 - Implement promises
 - Implement boxed types, for those variables which can have 2 types
 - Implement `JSON.parse()` and `JSON.stringify()` (depends on the above)
 - Implement libuv bindings and shim, fake and steal node's IO APIs
 - Implement ES5-style classes (possibly by turning them into ES6-style classes first)
 - Implement or fake commonJS (`require()`, `module.exports`) modules.
 - Implement several javascript APIs such as Date, Symbol, and Array (which currently is simply a C++ `std::vector`).

# Hey this is AMAZING I WANNA FORK IT SELL IT OR WHATEVER WHAT IS TEH LICENSSSS

Just have fun with it! WTFPL

