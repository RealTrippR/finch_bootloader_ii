**FINCH BOOTLOADER**

The Finch Bootloader is a compact 16-bit bootloader, designed as part of the Finch-8086 IBM PC/XT/AT compatible operating system.

<hr>

![](https://media4.giphy.com/media/v1.Y2lkPTc5MGI3NjExejR4ejAxemRjbzNkODdnNTJlcmI1ZmRqbnZrdHM5bTR2ZjB5czZiayZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/mzUWKoNj71A4f8ZJzX/giphy.gif)


**Usage**

The Finch Bootloader reads the master boot record and will list any partition marked as bootable.
The first 24 bytes of the first sector in a bootable partition must contain the boot header, which contains the name of the partition and information about where to load and jump to the partiton.

The bootloader must be placed in the first two sectors on disk.
For it to work, you will need to configure the MBR (offset 440 bytes from the binary) with a partition table.

Note that the Finch Bootloader does not check for any overlapping or invalid partitions, nor does it validate if the selected partition number is correct.
