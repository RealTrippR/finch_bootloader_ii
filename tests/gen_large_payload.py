LARGE_PAYLOAD_FILE = "payloads/largepayload.asm"
NUM_64KIB_BLOCKS = 1



LARGE_PAYLOAD_STUB = f"""
[BITS 16]

global _payload_entry
_payload_entry:

mov ax, 0x3
int 0x10
mov dx, 0
mov ds, dx
mov si, str
call _CL_putstr

.hng:
jmp .hng
mov dx, 0x9000
mov ds, dx

mov bp, 0

mov ax, {NUM_64KIB_BLOCKS}
.loop:
push ax

push dx

mov bp, 0
.inner_loop:

push bp
mov ax,0
mov ax, [bp]
call _CL_putword
pop bp

add bp,2
cmp bp, 65535
jb .inner_loop


pop dx
add dx, 4096

pop ax
dec ax
cmp ax,0
jne .loop


mov si, str_complete
xor ax,ax
mov ds, ax
call _CL_putstr
jmp hang

str_complete: db 13,10,"finished loop!",0



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

hang:
    jmp hang



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



str: db "Hello from largepayload.asm!",0


; pad until 0x9000 boundary
times 1000 - ($ - $$) db 0

data: dw """


with open(LARGE_PAYLOAD_FILE, "w") as f:
    f.write(LARGE_PAYLOAD_STUB)

    parts = []

    for i in range(NUM_64KIB_BLOCKS):
        for j in range(65536):
            parts.append(str(j)+",")
            
        DATA = " ".join(parts)
        f.write(DATA)