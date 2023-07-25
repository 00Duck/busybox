
#!/bin/bash

# Minimum kernel build requirements (minus mcelog since it was taken out of Debian)
# sudo apt install -y gcc make bash binutils libelf-dev flex bison pahole util-linux kmod e2fsprogs jfsutils reiserfsprogs xfsprogs squashfs-tools btrfs-progs pcmciautils quota ppp nfs-common procps udev grub-common iptables openssl bc python3-sphinx cpio

KERNEL_VERSION=6.1.1
BUSYBOX_VERSION=1.36.0
KERNEL_MAJOR=$(echo $KERNEL_VERSION | sed 's/\([0-9]*\)[^0-9].*/\1/')

mkdir -p src
cd src

    # KERNEL
    wget https://mirrors.edge.kernel.org/pub/linux/kernel/v$KERNEL_MAJOR.x/linux-$KERNEL_VERSION.tar.gz
    tar -xf linux-$KERNEL_VERSION.tar.gz
    cd linux-$KERNEL_VERSION
        make defconfig
        make -j$(nproc) || exit
    cd ..
    
    # BUSYBOX
    wget https://busybox.net/downloads/busybox-$BUSYBOX_VERSION.tar.bz2
    tar -xf busybox-$BUSYBOX_VERSION.tar.bz2
    cd busybox-$BUSYBOX_VERSION
        make defconfig
        # build as statically linked libraries
        sed 's/^.*CONFIG_STATIC[^_].*$/CONFIG_STATIC=y/g' -i .config
        make -j$(nproc) busybox || exit
    cd ..
cd ..

# Copy the kernel to the top level where the script is
cp src/linux-$KERNEL_VERSION/arch/x86_64/boot/bzImage .

# Make initial folders and initialization
mkdir -p initrd
cd initrd
    # bin - busybox binaries
    # dev - device files
    # proc - process files
    # sys - interaction with kernel
    mkdir -p bin dev proc sys

    # Populate bin folder
    cd bin
        cp ../../src/busybox-$BUSYBOX_VERSION/busybox .

        #symlink all of the programs listed in busybox
        for prog in $(./busybox --list); do
            ln -s ./busybox ./$prog
        done
    cd ..

    # Init script
    echo '#!/bin/sh' > init
    echo 'mount -t sysfs sysfs /sys' >> init
    echo 'mount -t proc proc /proc' >> init
    echo 'mount -t devtmpfs udev /dev' >> init
    echo 'sysctl -w kernel.printk="2 4 1 7"' >> init #sets log levels
    #echo 'clear' >> init
    echo 'echo -e "\n******************\nWelcome to blakeOS\n******************\n"' >> init
    echo '/bin/sh' >> init
    echo 'poweroff -f' >> init #if the shell is killed, shut down the machine

    chmod -R 777 .

    find . | cpio -o -H newc > ../initrd.img
cd ..

# standard start
#qemu-system-x86_64 -kernel bzImage -initrd initrd.img

# start without a separate qemu window and directly in the terminal
#qemu-system-x86_64 -kernel bzImage -initrd initrd.img -nographic -append 'console=ttyS0'