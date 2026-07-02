BDIR := ./bin
PDIR := ./payloads
UBDIR := ../bin

PAYLOAD_SRC := largepayload.asm
#PAYLOAD_SRC := payload1.asm


# build payloads
$(BDIR)/payload1.o: $(PDIR)/$(PAYLOAD_SRC)
	nasm -f elf32 -g $< -o $@

	i686-elf-ld -m elf_i386 \
	-L./bin -L../bin \
	-o "$(BDIR)/payload1.elf" \
	-T test.ld

	objcopy -O binary $(BDIR)/payload1.elf  $(BDIR)/payload1.bin




payload1: $(BDIR)/payload1.o

link: test.ld $(BDIR)/payload1.o $(UBDIR)/fboot.o
	i686-elf-ld -m elf_i386 \
	-L../bin -L./bin  \
	-o "$(BDIR)/fs.elf" \
	-T test.ld



to_bin:
	objcopy -O binary $(BDIR)/fs.elf  $(BDIR)/fs.o



build: payload1  link  to_bin

# this consolidates the binary, in the same memory layout as the elf
payloads: build writechs.py $(BDIR)/payload1.o $(PDIR)/$(PAYLOAD_SRC)
	py writechs.py