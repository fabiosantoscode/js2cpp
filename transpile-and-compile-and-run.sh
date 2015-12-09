#!/bin/sh
echo $1.js \> $1.cpp

bin/js2cpp < $1.js > $1.cpp && g++ -std=c++14 -Wall -Werror -O3 -I gc-7.2/include/ -I include/ $1.cpp && ./a.out

