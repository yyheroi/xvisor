#!/bin/bash

# LINUX_KERNEL_PATH=/mnt/e/00study/00code/linux-6.10/linux-6.10-rc5
LINUX_KERNEL_PATH=/home/yyh/workspace_/linux-5.15.0
XVISOR_PATH=/home/yyh/workspace_/xvisor
OPEN_SBI_PATH=/home/yyh/workspace_/xvisor/opensbi-1.6
busybox_version=1.33.1
BUSYBOX_PATH=/home/yyh/workspace_/xvisor/busybox-$busybox_version
## /mnt/e/00study/00code/xvisor/docs/riscv/riscv64-qemu.txt ##
export PATH=/opt/riscv64-22/riscv/bin:$PATH
export CROSS_COMPILE=riscv64-unknown-linux-gnu-
export ARCH=riscv
do_build_xvisor()
{
    cd $XVISOR_PATH
    make distclean
    make generic-64b-defconfig
    make -j12
    make -C tests/riscv/virt64/basic
}

do_build_opensbi()
{
    cd $OPEN_SBI_PATH
    make clean
    make PLATFORM=generic
}

do_build_busybox()
{
    cp $XVISOR_PATH/tests/common/busybox/busybox-${busybox_version}_defconfig $BUSYBOX_PATH/.config
    cd $BUSYBOX_PATH
    make oldconfig
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
}

do_build_linux() 
{
    cd $LINUX_KERNEL_PATH
    cp arch/riscv/configs/defconfig arch/riscv/configs/tmp-virt64_defconfig
    $XVISOR_PATH/tests/common/scripts/update-linux-defconfig.sh -p arch/riscv/configs/tmp-virt64_defconfig -f $XVISOR_PATH/tests/riscv/virt64/linux/linux_extra.config
    make O=$LINUX_KERNEL_PATH tmp-virt64_defconfig -j8
    make O=$LINUX_KERNEL_PATH Image dtbs -j8
}

do_setup_disk() 
{
    # Create disk image for Xvisor
    cd $XVISOR_PATH 
    mkdir -p ./build/disk/tmp
    mkdir -p ./build/disk/system
    cp -f ./docs/banner/roman.txt ./build/disk/system/banner.txt
    cp -f ./docs/logo/xvisor_logo_name.ppm ./build/disk/system/logo.ppm
    mkdir -p ./build/disk/images/riscv/virt64
    dtc -q -I dts -O dtb -o ./build/disk/images/riscv/virt64-guest.dtb ./tests/riscv/virt64/virt64-guest.dts
    cp -f ./build/tests/riscv/virt64/basic/firmware.bin ./build/disk/images/riscv/virt64/firmware.bin
    cp -f ./tests/riscv/virt64/linux/nor_flash.list ./build/disk/images/riscv/virt64/nor_flash.list
    cp -f ./tests/riscv/virt64/linux/cmdlist ./build/disk/images/riscv/virt64/cmdlist
    cp -f ./tests/riscv/virt64/xscript/one_guest_virt64.xscript ./build/disk/boot.xscript
    cp -f $LINUX_KERNEL_PATH/arch/riscv/boot/Image ./build/disk/images/riscv/virt64/Image
    dtc -q -I dts -O dtb -o ./build/disk/images/riscv/virt64/virt64.dtb ./tests/riscv/virt64/linux/virt64.dts
    cp -f $BUSYBOX_PATH/rootfs.img ./build/disk/images/riscv/virt64/rootfs.img
    genext2fs -B 1024 -b 32768 -d ./build/disk ./build/disk.img
    cp $OPEN_SBI_PATH/build/platform/generic/firmware/fw_jump.bin .
}

do_start()
{
    # qemu-system-riscv64 -M virt -m 512M -nographic \
    # -bios ./fw_jump.bin \
    # -kernel ./build/vmm.bin \
    # -initrd ./build/disk.img \
    # -append 'vmm.bootcmd="vfs mount initrd /;vfs run /boot.xscript"'
    # -d in_asm,cpu,int -serial tcp::1234,server,nowait

    /home/yyh/workspace_/qemu/output/qemu-system-riscv64 \
    -M virt \
    -m 1G \
    -nographic \
    -kernel ./build/vmm.bin \
    -initrd ./build/disk.img \
    -append 'vmm.bootcmd="vfs mount initrd /;vfs run /boot.xscript"'
    # -bios ./fw_jump.bin \

}

BUILD_XVISOR=flase
BUILD_LINUX=false
BUILD_BUSYBOX=false
BUILD_ALL=false
START_QEMU=false
BUILD_OPENSBI=false

while getopts "A:S:lbxos" arg
do
    case $arg in
        A)
            echo "will build all ."
            BUILD_ALL=true
            BUILD_ALL_ARGS=$OPTARG
            ;;
        l)
            echo "will build Linux ."
            BUILD_LINUX=true
            BUILD_LINUX_ARGS=$OPTARG
            ;;
        x)
            echo "will build xvisor"
            BUILD_XVISOR=true
            ;;
        b)
            echo "will build busybox"
            BUILD_BUSYBOX=true
            ;;
        s)
            echo "will start qemu"
            START_QEMU=true
            ;;
        o)
            echo "will build opensbi"
            BUILD_OPENSBI=true
            ;;
    esac
done


set -x

if [ "$BUILD_LINUX" = true ]; then
    do_build_linux
fi

if [ "$BUILD_BUSYBOX" = true ]; then
    do_build_busybox
fi

if [ "$BUILD_XVISOR" = true ]; then
    do_build_xvisor
    do_setup_disk
fi

if [ "$BUILD_OPENSBI" = true ]; then
    do_build_opensbi
fi

if [ "$BUILD_ALL" = true ]; then
    do_build_xvisor
    do_build_linux
    do_build_opensbi
    do_build_busybox
    do_setup_disk
fi

if [ "$START_QEMU" = true ]; then
    do_start
fi