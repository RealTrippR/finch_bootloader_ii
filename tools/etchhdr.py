import math
import sys
import os

args = sys.argv[1:]
#args = ["80", "2", "36",		"bin/fs.bin",	 "-m0", "0x19", "1024", "bin/payload1.bin", "-5", "0x800", "0", "0x8010"]


# usage:
# py writehdr.py <cyls> <heads> <sectors>   <disk_file>     <entry>

# entries are structured as
# <offset> <partition_file_name><*optional-N> <load_segment> <entry_segment> <entry_offset>
# ex.
# py writehdr.py 80 2 36	 bin/disk.bin	 1024 bin/entry.bin 0x800 0 0x8010



hasprinted=0
def print_usage():
    global hasprinted
    if (hasprinted==1):
        return
    print("Usages: \npy writehdr.py <cyls> <heads> <sectors>   <disk_file>     <entry>")
    print("Entries are structured as: \n<flags> <offset> <partition_file_name> <load_segment> <entry_segment> <entry_offset>")
    print("Entry flags:\n\t-m<idx> <signature>\t\t -- writes partition addresses into master boot record.\n\t\t\t\t-m0 0x10 would be the first entry, -m1 0x10 the second, and so on.")
    
    print("To clarify, the partition_file_name is only used to retrieve the size of the partition. This tool will NOT write the contents of that file into the disk. If the filename of the payload is followed by the minus(-) or (+) sign, its size will be offset by the following value.")
    hasprinted=1

def err(msg):
    print(F"Error: {msg}")
    print_usage()
    exit(-1)

def to_int(str):
    if (str[0:2]=='0x'):
        return int(str[2:],16)
    if (str[-1]=='h'):
        return int(str[:-1],16)
    
    return int(str,10)


def warn(msg):
    print(F"Warning: {msg}")



    
def offset_to_chs(offset):
    # c * (h * s)
    toff = offset / 512
    c = math.floor(toff / (DRIVE_HEADS * DRIVE_SECTORS))
    toff = toff % (DRIVE_HEADS * DRIVE_SECTORS)
    h = math.floor(toff / DRIVE_SECTORS)
    s = math.floor(toff % DRIVE_SECTORS)+1


    new_offset = (s-1) * BYTES_PER_SECTOR + BYTES_PER_SECTOR * h * c
    return [c,h,s]


def chs_to_bytes(chs):
    bchs = bytearray(3)
    bchs[0] =  chs[1]
    bchs[1] =  chs[2] & 0x3F
    bchs[1] |= (chs[1] >> 8) << 6 & 0xC0
    bchs[2] =  chs[0] & 0xff
    return bchs
 


def write_mbr_entry(file, index, partition_type, content_bytes_begin, content_byte_length):
    entry = bytearray(16)
    entry[0] = 0x80

    chs_first = offset_to_chs(content_bytes_begin)
    
    entry[1:4] = chs_to_bytes(chs_first)

    entry[4] = partition_type

    chs_last = offset_to_chs(math.ceil((content_bytes_begin+content_byte_length)/BYTES_PER_SECTOR) * BYTES_PER_SECTOR)
    entry[5:8] = chs_to_bytes(chs_last)

    print("CHS INFO [FOLLOWING VALUES ARE IN 512-BYTE SECTORS, NOT BYTES]")    
    print(f"CHS FIRST: \n\t[C:{chs_first[0]}  H:{chs_first[1]}  S:{chs_first[2]}]")
    print(f"CHS LAST: \n\t[C:{chs_last[0]}   H:{chs_last[1]}   S:{chs_last[2]}]")


    lba_begin   = math.floor(content_bytes_begin/BYTES_PER_SECTOR)
    lba_len     = math.ceil(content_byte_length/BYTES_PER_SECTOR)

    print("LBA INFO: [FOLLOWING VALUES ARE IN 512-BYTE SECTORS, NOT BYTES]")
    print(f"\tBEGIN: {lba_begin}")
    print(f"\tEND: {lba_begin+lba_len}")
    print(f"\tLEN: {lba_len}")
    entry[8:12] = lba_begin.to_bytes(4, byteorder='little')
    entry[12:16] = lba_len.to_bytes(4, byteorder='little')

    offset = index*16 + 446
    file.seek(offset)
    file.write(entry)



import shlex


def get_filename(s: str) -> tuple[str, str]:
    tokens = shlex.split(s)
    if not tokens:
        raise ValueError("Expected a filename")

    filename = tokens[0]
    rest = " ".join(tokens[1:])

    return filename, rest


BYTES_PER_SECTOR = 512

BOOTLOADER_SIZE = 1024

PAYLOAD_FILE_DIR = "bin/"
HEADER_SIZE = 12

DRIVE_CYLINDERS = 0
try:
    DRIVE_CYLINDERS = to_int(args[0])
except:
    err(f"drive_cylinders: invalid input: {args[0]}")

DRIVE_HEADS = 0
try:
    DRIVE_HEADS = to_int(args[1])
except:
    err(f"drive_heads: invalid input: {args[1]}")


DRIVE_SECTORS = 0
try:
    DRIVE_SECTORS = to_int(args[2])
except:
    err(f"drive_sectors: invalid input: {args[2]}")


DISK_FILENAME =""

try:
    DISK_FILENAME, _ = get_filename(args[3])
except:
    err(f"disk_filename: invalid input: {args[3]}")


try:
    with open(DISK_FILENAME, "rb+") as diskfile:
        diskfile.seek(510)
        b=bytes([0x55,0xAA])
        diskfile.write(b)
        print("Wrote bootsignature at 510.")



            
        argc=len(args)
        for i in range(4, argc, 5):
            argc=len(args)
            if (i>=argc):
                break
            
            write_to_mbr = -1
            mbr_sig = 0
            
            try:
                if (len(args[i])>2 and args[i][0:2] == '-m'):
                    write_to_mbr = to_int(args[i][2:3])
                    if (write_to_mbr<0 or write_to_mbr>3):
                        err(f"Invalid MBR partition index: {args[i]}")
                    del args[i]

                try:
                    mbr_sig = to_int(args[i])
                    if (mbr_sig < 0 or mbr_sig > 255):
                        err(f"The MBR signature {mbr_sig} must be an unsigned byte between 0 and 255.")
                    elif (mbr_sig==0):
                        warn("An MBR signature of 0x00 is marked as non-bootable.")
                        
                    del args[i]
                except:
                    err(f"The MBR signature {mbr_sig} must be an unsigned byte between 0 and 255.")


            except:
                err(f"Invalid usage of the -m flag: {args[i]}")


            offset=0
            try:
                offset = to_int(args[i])
            except:
                err(f"entry_offset: invalid input: {args[i]}")

            part_filename = ""
            szoffset = None
            szoffset_sign = None

            try:
                part_filename, rest = get_filename(args[i+1])
                
                #if (part_filename==DISK_FILENAME):
                   # err(f"The entry filename {part_filename} and the disk filename {DISK_FILENAME} cannot be equal")

                if (len(rest) and (rest[0] == '-' or rest[0]=='+')):
                    if (rest[0]=='-'):
                        szoffset_sign = 0
                    else:
                        szoffset_sign = 1
                    
                    if (len(rest[0]>1)):
                        szoffset = to_int(rest[1:])

                elif (args[i+2][0]=='-' or args[i+2][0]=='+'):
                    if (args[i+2][0]=='-'):
                        szoffset_sign = 0
                    else:
                        szoffset_sign = 1

                    if (len(args[i+2])>1):
                        szoffset = to_int(args[i+2][1:])
                        del args[i+2]

                    if (szoffset==None):
                        if (len(rest)>1):
                            szoffset = to_int(rest[1])
                        else:
                            szoffset = to_int(args[i+2])
                            del args[i+2]
                    if szoffset == None:
                        err(f"Invalid size offset directive.")


            except:
                err(f"partition_filename: invalid input: {args[i+1]}")

            
            load_segment = 0
            try:
                load_segment = to_int(args[i+2])
            except:
                err(f"load_segment: invalid input: {args[i+2]}")


            entry_segment = 0
            try:
                entry_segment = to_int(args[i+3])
            except:
                err(f"entry_segment: invalid input: {args[i+3]}")


            entry_offset = 0
            try:
                entry_offset = to_int(args[i+4])
            except:
                if (len(args)<i+5):
                    err(f"entry_offset is missing.")
                err(f"entry_offset: invalid input: {args[i+4]}")



            size = os.path.getsize(part_filename)
            if (szoffset):
                if szoffset_sign == 0:
                    size-=szoffset
                    if (size < 0):
                        err(f"Invalid size offset: A size offset of -{szoffset} will result in a negative file size for file {part_filename} of size {os.path.getsize(part_filename)}.")
                else:
                    size+=szoffset

            dsksize = os.path.getsize(DISK_FILENAME)

            #if the offset of the entry is greater than the disk filesize, add padding to the file
            if (offset>=dsksize):
                bytestoadd= (offset+1-dsksize)
                print(f"The offset of entry {part_filename} extends beyond the bounds of the disk file, {bytestoadd} bytes will be added prior to the partition contents.")
                padding=bytearray(bytestoadd)
                diskfile.write(padding)


            if (write_to_mbr!=-1):
                write_mbr_entry(diskfile, write_to_mbr, mbr_sig, offset, size)
                
            hdr = bytearray(HEADER_SIZE)

            hdr[0] = 0
            sec_count = math.ceil(size / 512)
            hdr[4:6] = sec_count.to_bytes(2, byteorder='little')
            hdr[6:8] = load_segment.to_bytes(2, byteorder='little')
            hdr[8:10] = entry_segment.to_bytes(2, byteorder='little')
            hdr[10:12] = entry_offset.to_bytes(2, byteorder='little')

            diskfile.seek(offset)
            diskfile.write(hdr)

            print(f"Successfully wrote the header of {part_filename}:")
            print(f"\t+ load segment: {load_segment}")
            print(f"\t+ entry segment: {entry_segment}")
            print(f"\t+ entry offset: {entry_offset}")


    print(f"\n============================\nCompleted etching partition headers into disk binary '{DISK_FILENAME}'.\n")

except FileNotFoundError as e: 
    print(f"Error Code: {e.errno}")      # Outputs: 2
    print(f"Message: {e.strerror}")       # Outputs: No such file or directory
    print(f"Missing File: {e.filename}")  # Outputs: missing_report.csv
    err(f"Failed to open disk file: {DISK_FILENAME}")
    
except FileExistsError: 
    err(f"Failed to open disk file: {DISK_FILENAME}")
except Exception as e:
    err(f"Unknown failure: {e}")