#!/bin/sh
echo $1

g++ -std=c++11 -Wall -Werror -O3 -I gc-7.2/include/ -I include/ -lrt -lpthread $1 && ./a.out

