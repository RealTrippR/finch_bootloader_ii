BDIR := ./bin
PDIR := ./payloads
UBDIR := ../bin

# build payloads
$(BDIR)/payload1.o: $(PDIR)/payload1.asm
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
payloads: build
	py writechs.py