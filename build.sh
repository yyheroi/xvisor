#!/bin/bash
export PATH=$PATH:/opt/atk-dlrk3568-5_10_sdk-toolchain/bin
export CROSS_COMPILE=aarch64-buildroot-linux-gnu-
MKIMAGE_BIN=/home/yyh/workspace_/linux_sdk/rkbin/tools/mkimage

# /home/yyh/workspace_/linux_sdk/buildroot/output/rockchip_rk3568/images
/* 编译uvmm.bin，修改defvonfig后需要重新生成.config */
make ARCH=arm generic-v8-defconfig
make -j8

/* 将xVisor指定为内核，编译为uvmm.bin用于烧写到单板 */
$MKIMAGE_BIN -A arm64 -O linux -T kernel -C none -a 0x00080000 -e 0x00080000 -n Xvisor -d build/vmm.bin build/uvmm.bin  