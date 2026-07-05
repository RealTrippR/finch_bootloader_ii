import sys

'''
entry format:
+0: str contents (array of uint8s forming a null-terminated ASCII string)
+16: end

-- the total size of an entry is 16.
There can be 4 entries in total, 1 for every partition.

The entries begin at an offset of 448 from the end of the first sector on disk. 
'''
WRITE_OFFSET_ABS = 512+468
MAX_NAME_LEN = 10
ENTRY_STRIDE = MAX_NAME_LEN+1

args = sys.argv[1:]

def print_usage():
    print("USAGE:\npy etch.py <file_to_etch> <partition_idx> <partition_name>, ...\n")

if ((len(args)-1)%2!=0):
    print(f"Error: invalid argument count of {len(args)}.")
    print("The number of args, excluding the file to etch, must be a multiple of 2.")
    print_usage()
    exit(0)

filename = args[0]
try:
    with open(filename, "rb+") as file:

        for i in range(1,len(args),2):
            index = 0

            try:
                index = int(args[i])
            except ValueError:
                print(f"Error: invalid index: {args[i]} - valid index range: [0 <= index <= 3]")
                exit(-1)

            if (index > 3 or index < 0):
                print(f"Error: invalid index: {index} - valid index range: [0 <= index <= 3]")
                exit(-1)

            name = args[i+1]

            if (len(name)>MAX_NAME_LEN):
                print(f"Error: invalid name: '{name}' the maximum name length of 15 characters.")
                exit(-1)

            entry = bytearray(MAX_NAME_LEN+1)
            entry[:len(name)] = name.encode('ascii')
            entry[len(name):len(name)+1] = int(0).to_bytes(1)
            file.seek(WRITE_OFFSET_ABS + ENTRY_STRIDE * index)
            file.write(entry)


except PermissionError:
    print(f"Error: cannot open '{filename}' for etching: insufficient permissions.")
    exit(-1)

except FileNotFoundError:
    print(f"Error: cannot open '{filename}' for etching: file not found.")
    exit(-1)

except Exception as error:
    print(f"Error: cannot open '{filename}' for etching.")
    print(f"Error details: {error}")
    exit(-1)

print(f"Successfully etched entries into '{filename}':")
for i in range(1,len(args),2):
    index = args[i]
    name = args[i+1]
    print(f'\t+{index} > \'{name}\'')