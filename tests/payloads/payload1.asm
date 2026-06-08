[BITS 16]


; LOADS 0x8000

; LOAD SEGMENT:  0x800
; LOAD OFFSET:   0x18
; ENTRY SEGMENT: 0x800
; ENTRY OFFSET:  0x18

global _payload_entry
_payload_entry:

    mov ax, 0x3
    int 0x10
    mov si, str ;0x80,0x3c ??

    call _CALL_putstr
    jmp hang



; ARGS:
; @param str_begin : ds:si : ptr to a null terminated string
; @brief very simple string output function, prints all characters of a string to the console
_CALL_putstr:
    mov ah, 0x0E
.loop:
    lodsb
    cmp al, 0
    je .ret
    int 0x10
    jmp .loop
.ret:
    ret

hang:
    jmp hang

str: db 13,10,"Hello from payload1.asm.",0