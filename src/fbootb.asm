%include "config.inc"

%if FIXED_LOAD == 0

[BITS 16]

; FINCH BOOTLOADER, COPYRIGHT (C) TRIPP R., 2025-2026
; THE 'B' PART OF THE BOOTLOADER, THE USER END
; THIS IS AN OPTIONAL COMPONENT, IT CAN BE DISABLED WITH BY SETTING THE PREPROCCESOR FLAG 
; FIXED_LOAD = 1

extern _aret
extern booterr
extern nonfixed_read_hdr_ret

global _bentry2
_bentry2:
    ; reset video mode
    mov ax, 0003h; https://www.ctyme.com/intr/rb-0069.htm
    int 0x10
    
    xor ax,ax
    mov ds,ax
    
    mov si, firststr
    call _CL_putstr

    mov al, 0xCD
    mov cx, 40
    call _CL_putbr
    
    mov si, sctr_hdr
    call _CL_putstr

    mov al, 0xCD
    mov cx, 16
    call _CL_putbr
    

    mov bp, 0x7C00+446
    mov si, 0x7E00+448
    mov cl, 0 ; current index
.skp_part:


    ; print sector info

    cmp byte [bp],0x80
    jne .nxt_part

    push si
    mov ax, 0x0E0D
    int 0x10
    mov ax, 0x0E0A
    int 0x10

    xor ax,ax
    mov al,cl
    call _CL_putword
    inc cl
    
    mov ax, 0x0E20
    int 0x10

    add bp, 1
    call _CL_put_chs



    push bp
    mov ah,3
    mov bh,0
    int 0x10
    mov ah,2
    mov dl, 14
    int 0x10
    pop bp

    add bp, 4
    call _CL_put_chs


    push bp
    mov ah,3
    mov bh,0
    int 0x10
    mov ah,2
    mov dl, 24
    int 0x10
    pop bp

    sub bp,5


    pop si
    push si
    call _CL_putstr
    pop si

.nxt_part:
    add si, 16
    add bp, 16
    cmp bp, 0x7C00+510
    jne .skp_part


    mov si, sel_msg
    call _CL_putstr
.retrykey:
    mov ah,0
    int 16h
    sub al, 48
    cmp al, 3
    ja .invalidkey

    mov cx,ax

    ; check if it's a valid, bootable partition
    mov bp, 0x7C00+446
    mov bl, 16
    mov ah,0
    mul bl
    add bp, ax
    cmp byte [bp],0 
    je .invalidkey

    mov ax, cx

    ; load first sector
    mov ah,0
    shl al, 4
    add ax, 446
    mov bx, ax
    
    jmp _aret

.invalidkey:
    mov al, 0xB6
    out 0x43, al

    mov ax, 1193
    out 0x42, al
    mov al, ah
    out 0x42, al

    in  al, 0x61
    or  al, 0x03
    out 0x61, al

    xor ax, ax
    mov es, ax
    mov bx, [es:0x46C]
    add bx, 3
.wait:
    mov ax, [es:0x46C]
    cmp ax, bx
    jb .wait
    
    in  al, 0x61
    and al, 0xFC
    out 0x61, al

; restore es
    ; es = 0x7C0, or memory address 0x7C00
    mov ax, 0x7C0
    mov es, ax

    jmp .retrykey

firststr: db 13,10,"FINCH BOOTLOADER (C) TRIPP R.",13,10,0
;firststr: db 0
; DATA ------------------------------------------
sctr_hdr: db 13,10,"N",0xBA,"START [chs]",0xBA,"END [chs]",0xC9,0
sel_msg: db 13,10,13,10,"> select:",0



global nonfixed_read_hdr
nonfixed_read_hdr:


    ; load first sector
    
    ; ik it seems odd to load the ending chs address first,
    ; but the sector read after this requires the registers to be set
    ; to data from the first chs address.

    ; load the ending CHS address
    add bx,5
    ; load ending chs address
    mov dh, [es:bx] ; head
    inc bx ; +1
    mov cl, [es:bx] ; sector
    inc bx ; +2
    mov ch, [es:bx] ; cylinder
    ; DATA, WILL BE USED TO DETERMINE HEAD READ BEHAVIOR
    mov [0x7C00+21], dh ; HEAD OF LAST ADDRESS
    mov [0x7C00+22], cx ; SECTOR,CYLINDER OF LAST ADDRESS
    ;mov [0x7C00+23], ch ; CYLINDER OF LAST ADDRESS

    ; load starting chs address
    sub bx, 6

    mov dh, [es:bx] ; head
    inc bx ; +1
    mov cl, [es:bx] ; sector
    inc bx ; +2
    mov ch, [es:bx] ; cylinder
    ; DATA, WILL BE USED TO DETERMINE HEAD READ BEHAVIOR
    mov [0x7C00+18], dh ; HEAD OF STARTING ADDRESS
    mov [0x7C00+19], cx ; SECTOR, CYLINDER OF STARTING ADDRESS
    ;mov [0x7C00+20], ch ; CYLINDER OF STARTING ADDRESS


    mov dl, [0x7C00+1] ; drive num
    mov bx, 512
    ; es:bx = load segment
    mov ax, 0x0201 ; read sector op code / sector count
    jmp nonfixed_read_hdr_ret



; PUT BYTE REPEATING
; CX: TIMES TO REPEAT (must not be 0)
; AL: BYTE
_CL_putbr:
    mov ah, 0x0E
.loop:
    cmp cx, 0
    je .ret
    int 0x10
    dec cx
    jmp .loop

.ret:
    ret



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
    ret

; Prints a chs at address in BP as C:H:S
; ARGS: 
; bp - address to CHS
_CL_put_chs:

    xor ah,ah
    mov al, [bp+2]
    call _CL_putword

    mov ax, 0x0E3A
    int 0x10

    xor ah,ah
    mov al, [bp]
    call _CL_putword

    mov ax, 0x0E3A
    int 0x10

    xor ah,ah
    mov al, [bp+1]
    call _CL_putword

    ret

%if ($ - $$) > 468
    %error "Bootloader-B exceeds 468 bytes."
%endif

%endif

