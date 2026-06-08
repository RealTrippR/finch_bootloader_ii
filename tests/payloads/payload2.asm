[BITS 16]

str: "Hello from payload2.asm."
%strlen str_len "Hello from payload2.asm."

_entry:
    mov ax, 0
    mov ds, ax

    mov si, str
    mov di, str+str_len+1

    call print_str
    jmp .hang


; str_begin : ds:si : ptr to the first character of the string
; str_end   : ds:di : a ptr to the end of the string (str_begin+strlen+1)
; very simple string output function
; prints all characters of a string to the console
print_str:
    mov ah, 0x0E
.loop:

    cmp si, di
    je .ret
    lodsb

    int 0x10

.ret:
    ret

.hang:
    jmp .hang