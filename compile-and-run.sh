#!/bin/sh
echo $1

g++ -std=c++14 -Wall -Werror -O3 -I gc-7.2/include/ -I include/ $1 && ./a.out

