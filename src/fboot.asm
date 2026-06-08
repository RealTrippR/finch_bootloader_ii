[BITS 16]


; it is very important that no sections are defined here, otherwise it could confuse the linker.

; if there are any issues with qemu breakpoint attaching, try steps in this order
; > just build
; cd tests
; > make payloads -B

; if that doesn't work, pray to alan turing and try again

%define HEADER_LOAD_ADDRESS 0x7C00+512

global _entry
_entry:
    ; reset DS segment
    xor ax, ax
    mov ds, ax
    mov di,0
    mov es,ax ; ES:DI must be zeroed due to BIOS error with query int.

    mov [0x7C00+1], dl ; DRIVE NO.

    ; QUERY DRIVE PARAMETERS
    ;https://www.ctyme.com/intr/rb-0621.htm
    mov ah, 08h
    int 13h
    mov [0x7C00], cl ; MAX SECTOR INDEX.
    

    ; print menu
    mov si, select_str
    call _CALL_putstr

    ; es = 0x7C0, or memory address 0x7C00
    mov ax, 0x7C0
    mov es, ax



    ; wait for input
    ; https://www.ctyme.com/intr/rb-1754.htm
    xor ah, ah
.keyloop:
    

    ;int 16h
    ;cmp ah,0
    ;je .keyloop

    ; al = keyinput
    ;sub al, '1'
    mov al, 0 ;  DEBUG ONLY
    jmp _load_bootable
    


; ARGS:
; @param al - MBR index
_load_bootable:
    ; load first sector
    mov ah,0
    shl al, 4
    add ax, 446+1
    mov bx, ax
    
    ; load first sector

    ; load first chs address
    mov dh, [es:bx] ; head
    inc bx ; +1
    mov cl, [es:bx] ; sector
    mov [0x7C00+2], cl; FIRST SECTOR IN PARTITION
    inc bx ; +2
    mov ch, [es:bx] ; cylinder
    ; DATA, WILL BE USED TO DETERMINE HEAD READ BEHAVIOR
    mov [0x7C00+18], dh ; HEAD OF STARTING ADDRESS
    mov [0x7C00+19], cl ; SECTOR OF STARTING ADDRESS
    mov [0x7C00+20], ch ; CYLINDER OF STARTING ADDRESS

    mov al, 1 ; sector count
    mov dl, [0x7C00+1]
    mov bx, 512
    ; es:bx = load segment
    mov ah, 0x02 ; read sector op code

    int 0x13 ; sector interrupt
    
    jc .booterr


    ; COPY HEADER DATA
    mov ax,[HEADER_LOAD_ADDRESS + 14]
    mov [0x7C00+6], ax   ; SECTOR COUNT
    mov bx,[HEADER_LOAD_ADDRESS + 16]
    mov [0x7C00+8], bx   ; LOAD SEGMENT
    mov ax, [HEADER_LOAD_ADDRESS + 18]
    mov [0x7C00+10], ax  ; LOAD OFFSET
    ; ENTRY SEGMENT: HEADER_LOAD_ADDRESS + 20
    ; LOAD_SEGMENT: HEADER_LOAD_ADDRESS + 22


    

    ; check if on a boundary
    push cx


;offset /= 16;
;addr = segment*16+offset;
;mod = addr%65536; - this is not needed since 16-bit addition overflow will act as modulo
;mod %= 4096
;if mod is greater than 4096-32, it's on a boundary 

    ; AX = offset
    shr ax, 4
    ; BX = segment
    add ax, bx
    shr ax, 4

    ; AX now holds address, (/16)
    cmp ax, 4096-32
    ja .read_boundary

    shr ax, 5
    mov dl, 127
    sub dl, al ; DL now holds the sectors till next boundary


    pop cx
; the disk controller cannot read across heads, and it can't read across 64kib boundaries.
    ; CL: sector count till next head
    ; DL: sector count till boundary

    cmp cl, dl
    jl .clmin
        mov cl, dl
    .clmin:

    ; cl holds the min of dl, cl, the min readable sector count


    ; read sectors

    ; load address: [es:bx]
    ; es:bx
    mov es, [HEADER_LOAD_ADDRESS + 16]
    mov bx, [HEADER_LOAD_ADDRESS + 18]  ; LOAD OFFSET
   

    mov ah, 02
    mov al, cl ; number of sectors to read
    mov ch, [0x7C00+20] ;cyl
    mov cl, [0x7C00+19] ;sector
    mov dh, [0x7C00+18] ;head
    mov dl, [0x7C00+1] ;drive

    int 0x13

    ; ADD SECTORS TO CHS ADDRESS AT 0x7C00+18



    mov cl, [0x7C00] ; MAX SECTOR HEAD ON DRIVE
    sub cx, [0x7C00+2] ; FIRST SECTOR IN PARTITION
    cmp cx, 65023
    jl .add_as_offset
.add_as_segment:
    add word [0x7C00+8], 512/16

.add_as_offset:
    add word [0x7C00+10], 512
    




    mov ax, [HEADER_LOAD_ADDRESS + 20]
    mov ax, [HEADER_LOAD_ADDRESS + 22] 
    push word [HEADER_LOAD_ADDRESS + 20]   ; ENTRY SEGMENT
    push word [HEADER_LOAD_ADDRESS + 22]   ; ENTRY OFFSET

    retf ;ret far is the same as jmp far (but uses stack params)







.read_boundary:
    ret

.hang:
    jmp .hang


.booterr:
    jmp .booterr

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


select_str: db "select:",0