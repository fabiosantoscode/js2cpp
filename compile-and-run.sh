#!/bin/sh
echo $1

g++ -std=c++14 -Wall -Werror -O3 -Ldeps -I gc-7.2/include/ -I include/ -I deps/libuv/include -lrt -lpthread $1 -luv && ./a.out

