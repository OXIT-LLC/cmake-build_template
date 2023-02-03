#!/bin/sh

cd build/debug
cmake -G Ninja -DCMAKE_BUILD_TYPE=Debug -DCMAKE_TOOLCHAIN_FILE=../../arm-bare-metal.cmake ../..
cd ../release
cmake -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_TOOLCHAIN_FILE=../../arm-bare-metal.cmake ../..
cd ../..
