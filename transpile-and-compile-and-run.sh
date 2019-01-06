#!/bin/sh
echo $1.js \> $1.cpp

bin/js2cpp < $1.js > $1.cpp && g++ -Wall -O3 -I gc-7.2/include/ -I include/ -lrt -lpthread $1.cpp && ./a.out

