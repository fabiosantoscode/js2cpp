#!/bin/sh
echo $1.js \> $1.cpp

bin/js2cpp < $1.js > $1.cpp && g++ -std=c++14 -Wall -O3 -Ldeps -I gc-7.2/include/ -I include/ -I deps/libuv/include -lrt -lpthread $1.cpp deps/libuv.a && ./a.out

