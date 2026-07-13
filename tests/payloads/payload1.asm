[BITS 16]


; LOADS 0x8000

; LOAD SEGMENT:  0x0800
; LOAD OFFSET:   0x0018
; ENTRY SEGMENT: 0x0000
; ENTRY OFFSET:  0x8018

er: db "ENTRY"
global _start
_start:
    
    mov ax, 0x3
    int 0x10
    mov si, str

    call _CL_putstr

    mov ax, 15

    call _CL_putword

    jmp hang



; ARGS:
; @param str_begin : ds:si : ptr to a null terminated string
; @brief very simple string output function, prints all characters of a string to the console
_CL_putstr:
    mov ah, 0x0E
.loop:
    lodsb
    cmp al, 0
    je .ret
    int 0x10
    jmp .loop
.ret:
    ret


; ARGS:
; @param AX: 16-bit unsigned integer [PRESERVED]
; @brief outputs an unsigned 16-bit integer to the console
_CL_putword:
    pusha
    mov dx,0
    push dx
.s:
    ; MOD. DX, AX, BX
    mov dx, 0
    mov bx, 10
    div bx
    add dx, 48
    push dx

    cmp ax,0
    jne .s
.p:
    pop dx
    cmp dx,0
    je .r
    mov al, dl
    mov ah, 0x0E
    int 0x10
    jmp .p
.r:
    popa
    ret


hang:
    jmp hang

str: db "+=+ STR_BEGIN +=+",13,10,"Hello from payload1.asm.",13,10,0