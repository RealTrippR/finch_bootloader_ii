# Finch Bootloader II

The finch bootloader is a minimal bootloader
designed to be as compact and performant as possible.
It requires only 512 bytes of disk space for fixed-selection mode 
and 1024 when configured in user-selection mode.


![Example User Interface Configuration](https://media2.giphy.com/media/v1.Y2lkPTc5MGI3NjExMTZiOW81bGx5eXN4dGx0ajNrY2oyN2t2OGZvcjBuM25vYXo5ZHVidiZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/i8806kk0UcDOafFx8q/giphy.gif)





```

USER'S MANUAL

Finch Bootloader for the IBM PC

COPYRIGHT (C) TRIPP R., 2025-2026


ABOUT
---------------------------------------------------------
    The finch bootloader is a minimal bootloader
designed to be as compact and performant as possible.
It requires only 512 bytes of disk space for fixed-selection mode 
and 1024 when configured in user-selection mode.

    The two sectors are referred to as 'SECTION A' and 'SECTION B',
SECTION B is only needed in user-interface mode.



FIXED SELECTION MODE:
---------------------------------------------------------
    Fixed selection mode gives no user prompt for 
selecting the partition to boot from; it
boots to the partition at a hardcoded index.

This is configured by the 
'FIXED_LOAD' 
and 
'FIXED_LOAD_INDEX'
macros defined in fboot.asm.

FIXED_LOAD is enabled when it is defined as 1,
and disabled when defined as 1.



USER SELECTION MODE
---------------------------------------------------------
    User selection mode is the alternative to fixed
selection mode. The bootloader jumps to the user interface
code, loaded from the 2nd sector ['SECTION B'] on disk.
This gives the user to boot from any partition in the master boot
record that does not have a status byte of 0. The selected
partition index is checked to ensure that it is a valid and
bootable partition, a short beep is emitted to indicate
an invalid selection.

    Displayed to the user is the index of the partitions,
the first and last CHS addresses, and the name of the 
partition, if applicable. The names of the partitions must
be embedded at an offset of 448 bytes within the user interface
sector, with a 11 byte stride. The names are formatted as
null-terminated ascii strings.


ETCHING PARTITION DATA INTO SECTION-B
---------------------------------------------------------
    The names of any bootable partitions (that is, a
partition which does not have a status byte of 0) must be
etched into a the B section at an offset of 448 bytes from
the start of the 2nd sector on the disk (the B section.)
The names are to be organized at a stride of 11 bytes,
formatted as null terminated ASCII strings. String length
may range to at least 0 characters and at most 15 characters.

    A simple python etching script is included with the
finch bootloader. It can be used on any binary:

    py etch.py <filename> <partition index> <partition name> ...

For example:

    py etch.py "fs.bin   0 finch"

    py etch.py "fs.bin   0 os_1   1 os_2"

The degree of whitespace is arbitary, so long as
it has no effect on the number and order of 
script arguments.



ON PROGRAM ENTRY
---------------------------------------------------------
    Finch makes no guarantee to the value of any registers
on program entry, other than the instruction pointer and the code 
segment, which are set to the entry offset and the entry segment,
respectively. In user interface mode, the contents of the video
buffer will not be cleared or modified before
execution is handed to the user code.

    It is recommend to initialize all data, segments, registers
immediately after the boot process is complete.


FORMATTING PARTITIONS
---------------------------------------------------------
    The first 12 bytes of the first sector in a bootable partition
must consist of a formatted header. This header contains the data
required for the finch bootloader to load the partition at a given
address and jump to a code entry point upon completion.

    Since the first 12 bytes are reserved for the header,
the code entry point should be at least 12 bytes after
the load point.


    All binary data, unless specified otherwise, is assumed to be
in little-endian format.




HEADER FORMAT: 
    <str>: <i8: length><content: bytes>
---------------------------------------------------------
<i8> mode: (0=8086 16bit, all other values are reserved!)

in mode 0:
    &mode+4:
        <i16> kernel_size_512 (size, in bytes / 512)
    +6:
        <i16> load segment
    +8:
        <i16> entry segment
    +10:
        <i16> entry offset
    &mode+12:

```