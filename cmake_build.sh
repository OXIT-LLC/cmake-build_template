#!/bin/bash
git submodule update --init --recursive &

read -p "Clearing the project build folder and runing CMake build, continue? (Y/n) " yn

case $yn in 
	y ) echo ok, we will proceed;;
	n ) echo exiting...;
		exit;;
	* ) echo defualt proceed;;
esac

clear &&
rm -rf build &&
# read -p "Press any key to resume ..."
mkdir build && 
cd build &&
cmake -DCMAKE_TOOLCHAIN_FILE=./target/stm32wl/arm-none-eabi-gcc.cmake -DCMAKE_BUILD_TYPE=Debug .. &&
cmake --build . -- -j 4