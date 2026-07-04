[private]
default:
	@just -f '{{ justfile() }}' --list

src := "./src"
out := "./bin"

build:
	#!/usr/bin/env sh
	set -ex

	SRC=$(realpath "{{src}}")
	OUT=$(realpath "{{out}}")

	mkdir -p "$OUT" && cd "$OUT" || exit

	nasm -f elf32 -g \
		-o fboot.o \
		-I "$SRC" \
		"$SRC/fboot.asm"


	nasm -f elf32 -g \
		-o fbootb.o \
		-I "$SRC" \
		"$SRC/fbootb.asm"

	i686-elf-ld -m elf_i386 \
		-o fboot.elf \
		-T "$SRC/boota.ld" \
		fboot.o \
		fbootb.o

	i686-elf-ld -m elf_i386 \
		-o fbootb.elf \
		-T "$SRC/bootb.ld" \
		fboot.o \
		fbootb.o



	objcopy -O binary fboot.elf fboot.bin
	objcopy -O binary fbootb.elf fbootb.bin

clean:
	#!/usr/bin/env sh
	set -ex
	OUT=$(realpath "{{out}}")

	rmdir "$OUT" 
	mkdir "$OUT"