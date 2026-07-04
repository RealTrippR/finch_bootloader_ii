ENTRY(_entry)

SECTIONS
{
	. = 0x7C00;
	.fboot : AT(0x7C00) SUBALIGN(4) {
		fboot.o(.text)
	}
}
