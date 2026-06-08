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


	i686-elf-ld -m elf_i386 \
		-o fboot.elf \
		-T "$SRC/boot.ld" \
		fboot.o

	objcopy -O binary fboot.elf fboot.bin

clean:
	#!/usr/bin/env sh
	set -ex
	OUT=$(realpath "{{out}}")

	rmdir "$OUT" 
	mkdir "$OUT"