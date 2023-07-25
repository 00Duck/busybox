
#!/bin/bash

# standard start
qemu-system-x86_64 -kernel bzImage -initrd initrd.img

# start without a separate qemu window and directly in the terminal
#qemu-system-x86_64 -kernel bzImage -initrd initrd.img -nographic -append 'console=ttyS0'