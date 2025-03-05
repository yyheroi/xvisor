#!/bin/bash

# export PATH=/opt/riscv/bin:$PATH
# export CROSS_COMPILE=riscv64-unknown-linux-gnu-
export CROSS_COMPILE=riscv64-linux-gnu-
export ARCH=riscv
# wget https://busybox.net/downloads/busybox-1.31.1.tar.bz2
busybox_version=1.31.1
XVISOR_PATH=/home/yyh/workspace_/xvisor
BUSYBOX_PATH=/home/yyh/workspace_/xvisor/busybox-$busybox_version
cd $BUSYBOX_PATH

cp $XVISOR_PATH/tests/common/busybox/busybox-${busybox_version}_defconfig $BUSYBOX_PATH/.config
# make menuconfig  # 设置静态编译：Settings → Build Options → Build static binary
# sudo cp /usr/include/tirpc/rpc /usr/include/ 
# sudo cp /usr/include/tirpc/netconfig.h /usr/include/
make oldconfig
make clean
make LDFLAGS="-static -Wl,--start-group -lm -lresolv -lc -Wl,--end-group"
# make oldconfig && make clean
# make ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- -j$(nproc)
# make -j$(nproc) all
make install

mkdir -p ./_install/etc/init.d
mkdir -p ./_install/dev
mkdir -p ./_install/proc
mkdir -p ./_install/sys
ln -sf /sbin/init ./_install/init
cp -f $XVISOR_PATH/tests/common/busybox/fstab ./_install/etc/fstab
cp -f $XVISOR_PATH/tests/common/busybox/rcS ./_install/etc/init.d/rcS
cp -f $XVISOR_PATH/tests/common/busybox/motd ./_install/etc/motd
cp -f $XVISOR_PATH/tests/common/busybox/logo_linux_clut224.ppm ./_install/etc/logo_linux_clut224.ppm
cp -f $XVISOR_PATH/tests/common/busybox/logo_linux_vga16.ppm ./_install/etc/logo_linux_vga16.ppm
cd ./_install; find ./ | cpio -o -H newc > ../rootfs.img; cd -