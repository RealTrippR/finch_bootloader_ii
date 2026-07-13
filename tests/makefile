BDIR := ./bin
PDIR := ./payloads
UBDIR := ../bin

#PAYLOAD_SRC := largepayload.asm
PAYLOAD_SRC := payload1.asm


# build payloads
$(BDIR)/payload1.o: $(PDIR)/$(PAYLOAD_SRC)
	nasm -f elf32 -g $< -o $@

	objcopy -O binary $(BDIR)/payload1.o  $(BDIR)/payload1.bin




payload1: $(BDIR)/payload1.o

link: test.ld $(BDIR)/payload1.o $(UBDIR)/fboot.o
	i686-elf-ld -m elf_i386 \
	-L../bin -L./bin  \
	-o "$(BDIR)/fs.elf" \
	-T test.ld



to_bin:
	objcopy -O binary $(BDIR)/fs.elf  $(BDIR)/fs.bin



build: payload1  link  to_bin

#writechs:
#	py writechs.py
writechs:
	py ../tools/etchhdr.py		80 2 36		$(BDIR)/fs.bin	 -m0 0x19 1024 $(BDIR)/payload1.bin 0x800 0 0x8010

etch: $(BDIR)/fs.bin
	py ../tools/etchname.py $(BDIR)/fs.bin 0 FINCH

# this consolidates the binary, in the same memory layout as the elf
payloads: build writechs etch

