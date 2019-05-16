#!/bin/bash

export PATH="/opt/gcc-arm-none-eabi/bin:$PATH"
git submodule update --init
cd contiki-ng
cd ../application
make -j`nproc` TARGET=cc2538dk
cp *cc2538dk ../artifacts
cd ../

/opt/renode/tests/test.sh -r artifacts contiki-ng.robot
