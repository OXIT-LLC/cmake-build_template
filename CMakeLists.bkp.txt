cmake_minimum_required(VERSION 3.0)

# !!!Set your project name here!!!
SET(PROJECTNAME my_project)

project("${PROJECTNAME}")

set (CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/bin)
set (CMAKE_VERBOSE_MAKEFILE ON)
SET(ASM_OPTIONS "-x assembler-with-cpp")

ENABLE_LANGUAGE(C CXX ASM)

#
# !!! uncomment and set CMSIS location here !!!
# for example: "C:/projects/CMSIS"

#SET(CMSISDIR "PLEASE_SET_THIS_PATH")

if (NOT CMSISDIR)
  message(FATAL_ERROR "Please set the CMSIS path in CMakeLists.txt" )
endif()

#
# Setup the processor definitions
#
# !!!REPLACE THE PROCESSOR DEFINITION HERE!!!!
add_definitions(-DSTM32F411xE -DHSE_VALUE=8000000 -DHSI_VALUE=16000000 -DARM_MATH_CM4)
SET(CPUFLAGS "-mcpu=cortex-m4 -mfloat-abi=hard -mfpu=fpv4-sp-d16 -mthumb")

#
# Set the target specific linker file here
#
SET(LINKERFILE "${CMAKE_SOURCE_DIR}/linker/STM32F411RE_FLASH.ld")

SET(CMAKE_ASM_FLAGS "${CMAKE_ASM_FLAGS} ${CPUFLAGS} -Wall  -fno-common  -ffunction-sections  -fdata-sections  -ffreestanding  -fno-builtin  -mapcs  -std=gnu99")
SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O2 -MMD ${CPUFLAGS}  -std=gnu++0x -felide-constructors -fno-exceptions -fno-rtti" )
SET(CMAKE_C_FLAGS   "${CMAKE_C_FLAGS} -O2  -MMD ${CPUFLAGS} " )

SET(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,--gc-sections ${CPUFLAGS} -fno-rtti -fno-exceptions -T${LINKERFILE} -Xlinker -Map=output.map")

# !!! change target specific include paths here !!!
INCLUDE_DIRECTORIES(${CMSISDIR}/Include)
INCLUDE_DIRECTORIES(${CMSISDIR}/Device/ST/STM32F4xx/Include)

# !!! change the target specific boot code files here!!!
add_executable(${PROJECTNAME}
    ${CMSISDIR}/Device/ST/STM32F4xx/Source/Templates/gcc/startup_stm32f411xe.s
    ${CMSISDIR}/Device/ST/STM32F4xx/Source/Templates/system_stm32f4xx.c
    ${CMAKE_SOURCE_DIR}/src/main.cpp)

add_custom_command(TARGET ${PROJECTNAME} POST_BUILD COMMAND ${ARMTOOLPATH}/bin/arm-none-eabi-size $<TARGET_FILE:${PROJECTNAME}>
                                                   COMMAND ${ARMTOOLPATH}/bin/arm-none-eabi-objcopy -O binary -R .eeprom $<TARGET_FILE:${PROJECTNAME}> $<TARGET_FILE:${PROJECTNAME}>.bin
                                                   COMMAND ${ARMTOOLPATH}/bin/arm-none-eabi-objcopy -O srec -R .eeprom $<TARGET_FILE:${PROJECTNAME}> $<TARGET_FILE:${PROJECTNAME}>.srec
                                                   COMMAND ${ARMTOOLPATH}/bin/arm-none-eabi-objcopy -O ihex -R .eeprom $<TARGET_FILE:${PROJECTNAME}> $<TARGET_FILE:${PROJECTNAME}>.ihex
                                                   COMMAND ${ARMTOOLPATH}/bin/arm-none-eabi-objdump -x -d $<TARGET_FILE:${PROJECTNAME}> >$<TARGET_FILE:${PROJECTNAME}>.lst)
