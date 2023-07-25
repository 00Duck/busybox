
#!/bin/bash

KERNEL_VERSION=6.1.1
BUSYBOX_VERSION=1.36.0
KERNEL_MAJOR=$(echo $KERNEL_VERSION | sed 's/\([0-9]*\)[^0-9].*/\1/')

sudo rm initrd.img
sudo rm -rf initrd


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