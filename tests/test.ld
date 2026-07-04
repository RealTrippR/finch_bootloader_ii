ENTRY(_entry)

/* https://users.informatik.haw-hamburg.de/~krabat/FH-Labor/gnupro/5_GNUPro_Utilities/c_Using_LD/ldLinker_scripts.html */

SECTIONS
{ 

	. = 0x7C00;
	.fboot : AT(0x7C00) SUBALIGN(4) {
		fboot.o(.text)
	}

	/* prevent overwrite */
	ASSERT(. <= 0x7DBE, "Bootloader-A exceeds 446 bytes")



	/* https://www.reddit.com/r/C_Programming/comments/147pegg/pad_zeros_to_the_end_of_output_binary_until_its/ */
	.pad : {
		. = . + (512 - (. % 512)) % 512;
		BYTE(0)
	}
	. = 0x7DFE;
	.bootsig : {
		SHORT(0xAA55);
	}
	

	. = 0x7E00;
	.fbootb : AT(0x7E00) SUBALIGN(4) {
		fbootb.o(.text)
	}

	/* https://www.reddit.com/r/C_Programming/comments/147pegg/pad_zeros_to_the_end_of_output_binary_until_its/ */
	.pad : {
		. = . + (512 - (. % 512)) % 512;
		BYTE(0)
	}


	/* it is incredibly important to make note of alignment issues - the linker script will automatically move files forward to the next boundary,
	even if no alignment is specific (default is 16).*/
	
	
	/*0x8000  [+18] to make room for header*/
    . = 0x8010; /* note that 8 bytes of padding are added to align it on 16 byte boundary, I couldn't get ALIGN(1) or SUBALIGN(1) to fix the issue. */
    .payload1 : AT(0x8004) {
		payload1.o(.text)
	}
}


