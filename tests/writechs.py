import math

DRIVE_SECTORS = 36
DRIVE_HEADS = 2
DRIVE_CYLINDERS = 80
BYTES_PER_SECTOR = 512

BOOTLOADER_SIZE = 512
FS_DST_DIR = "bin/fs.bin"
FS_SRC_DIR = "bin/fs.o"

PAYLOAD_FILE_DIR = "bin/"
HEADER_SIZE = 24


PAYLOAD_INFOS = [ 
    {
        "FILE": "payload1.bin",
        "NAME": "payload1",
        "LOAD_SEGMENT": 0,
        "LOAD_OFFSET": 0x8000,
        "ENTRY_SEGMENT": 0,
        "ENTRY_OFFSET": 0x8018,
        "FILE_OFFSET": 1024
    }
]



PAYLOAD_INFO=[]

PAYLOADS = []

#fs = bytearray(262144)
fs = ""
with open(FS_SRC_DIR, "rb") as file:
    fs = bytearray(file.read())




class header:
   def  __init__(self): 
        self.name = ""
        self.mode = 0
        self.size = 0
        self.load_segment = 0
        self.load_offset = 0
        self.entry_segment = 0
        self.entry_offset = 0
        self.file_offset = 0

class payload:
    def __init(self):
        self.name = ""
        self.contents = []
        self.header = header()


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
 


def write_mbr_entry(index, partition_type, content_bytes_begin, content_byte_length):
    offset = index*16 + 446
    fs[offset] = 0x80

    chs_first = offset_to_chs(content_bytes_begin)
    
    fs[offset+1:offset+4] = chs_to_bytes(chs_first)

    fs[offset+4] = partition_type

    chs_last = offset_to_chs(math.ceil((content_bytes_begin+content_byte_length)/BYTES_PER_SECTOR) * BYTES_PER_SECTOR)
    fs[offset+5:offset+8] = chs_to_bytes(chs_last)

    lba_begin   = math.floor(content_bytes_begin/BYTES_PER_SECTOR)
    lba_len     = math.ceil(content_byte_length/BYTES_PER_SECTOR)
    fs[offset+8:offset+12] = lba_begin.to_bytes(4, byteorder='little')
    fs[offset+12:offset+16] = lba_len.to_bytes(4, byteorder='little')

    

def write_payload(payload: payload, accum, size_override=None):
    offset = accum

    old_size =payload.header.size
    if size_override != None:
        payload.header.size = size_override

    hdr_begin = offset
    offset+=HEADER_SIZE
    hdr = bytearray(HEADER_SIZE)

    hdr[0] = payload.header.mode
    hdr[1] = len(payload.name)
    hdr[2:14] = payload.name
    sec_count = math.ceil(payload.header.size / 512)
    hdr[14:16] = sec_count.to_bytes(2, byteorder='little')
    hdr[16:18] = payload.header.load_segment.to_bytes(2, byteorder='little')
    hdr[18:20] = payload.header.load_offset.to_bytes(2, byteorder='little')
    hdr[20:22] = payload.header.entry_segment.to_bytes(2, byteorder='little')
    hdr[22:24] = payload.header.entry_offset.to_bytes(2, byteorder='little')



    fs[hdr_begin:hdr_begin+len(hdr)] = hdr
    fs[offset:offset+len(payload.contents)] = payload.contents
    
    # pad to 512 bytes
    padding = len(payload.contents) % 512
    fs[offset+offset+len(payload.contents):offset+offset+len(payload.contents)+padding] = bytearray(padding)

    payload.header.size=old_size
    


# load payloads
for i in range(0, len(PAYLOAD_INFOS)):
    INFO = PAYLOAD_INFOS[i]
    INFO["NAME"] = INFO["NAME"].ljust(12, '\0')
    with open(PAYLOAD_FILE_DIR+INFO["FILE"], "rb") as file:
        contents = file.read()
        pl = payload()
        pl.header = header()

        if "FILE_OFFSET" in INFO:
            contents = contents[INFO["FILE_OFFSET"]:]
            pl.header.file_offset = INFO["FILE_OFFSET"]

        pl.contents = contents
        pl.name = bytearray(INFO["NAME"], "ascii")
        if len(pl.name) > 12:
            raise Exception("Name exceeds 12 characters")
        
        pl.header.mode = 0
        pl.header.entry_offset = INFO["ENTRY_OFFSET"]
        pl.header.entry_segment = INFO["ENTRY_SEGMENT"]
        pl.header.load_offset = INFO["LOAD_OFFSET"]
        pl.header.load_segment = INFO["LOAD_SEGMENT"]
        pl.header.size = len(contents)
        PAYLOADS.append(pl)



accum = 0
for i in range(0, len(PAYLOADS)):
    pl = PAYLOADS[i]
    write_mbr_entry(i, 0x19, BOOTLOADER_SIZE, pl.header.size-BOOTLOADER_SIZE)
    write_payload(PAYLOADS[i], accum+BOOTLOADER_SIZE)
    accum+=pl.header.size

#bootsig
fs[510] = 0x55
fs[511] = 0xAA


#write fs
with open(FS_DST_DIR, "wb") as file:
    file.write(fs)