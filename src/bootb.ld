ENTRY(_bentry2)

SECTIONS
{
	. = 0x7E00;
	.fbootb : AT(0x7E00) SUBALIGN(4) {
		fbootb.o(.text)
	}
}
