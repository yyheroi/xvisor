#!/bin/bash

export PATH=/opt/riscv/bin:$PATH
export CROSS_COMPILE=riscv64-unknown-linux-gnu-
export ARCH=riscv

make defconfig
# make menuconfig  # 设置静态编译：Settings → Build Options → Build static binary
make -j$(nproc)

if [ -d rootfs ]; then
    rm rootfs -rf
fi

mkdir -p rootfs/{bin,dev,etc/init.d,lib,proc,sys,root}
cp busybox rootfs/bin/
ln -s rootfs/bin/busybox rootfs/bin/sh

inittab_PATH=rootfs/etc/inittab
touch $inittab_PATH
echo "::sysinit:/etc/init.d/rcS" >> $inittab_PATH
echo "::respawn:-/bin/sh" >> $inittab_PATH
echo "::ctrlaltdel:/sbin/reboot" >> $inittab_PATH

rcS_PATH=rootfs/etc/init.d/rcS
touch $rcS_PATH
echo "#!/bin/sh" >> $rcS_PATH
echo "mount -t proc none /proc" >>  $rcS_PATH
echo "mount -t sysfs none /sys" >>  $rcS_PATH
echo "mdev -s" >> $rcS_PATH

sudo mknod rootfs/dev/console c 5 1
sudo mknod rootfs/dev/null c 1 3

dd if=/dev/zero of=rootfs.img bs=1M count=16
mkfs.ext4 -F rootfs.img
mkdir -p mnt
sudo mount -o loop rootfs.img mnt
sudo cp -ra rootfs/* mnt/
sudo umount mnt
rmdir mnt