#!/bin/bash
export PATH=/opt/riscv64-22/riscv/bin:$PATH
export CROSS_COMPILE=riscv64-unknown-linux-gnu-
export ARCH=riscv

make clean
make PLATFORM=generic
# make ARCH=rv64gc_zifencei PLATFORM=generic CROSS_COMPILE=riscv64-unknown-elf-
