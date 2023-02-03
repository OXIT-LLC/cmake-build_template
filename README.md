# ARM GCC + CMAKE Template project

You need to do the following:

* name your project in CMakeLists.txt
* change the paths of the ARM tool chain in CMakeLists.txt and arm-bare-metal.cmake
* change the target boot files (should be part of CMSIS) in CMakeLists.txt
* copy a linker file for your target CPU into the linker dir and make sure the CMakeLists.txt refers to it.
* add/remove any defines specific to your target in CMakeLists.txt

You need to have the following installed:
* Ninja build tools (in current path)
* CMake 3 or better.
* ARM GCC toolchain.

Initialise your project by running 'bootstrap.bat' or 'bootstrap.sh'. This is only needed once.

Compile your project by going to build/debug or build/release and run ninja.
