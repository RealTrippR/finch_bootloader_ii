[BITS 16]

%define FIXED_LOAD 0
%define FIXED_LOAD_INDEX 0

%define LOAD2ENTRY 0x7C00+512
%define STACK 0x7A00

; it is very important that no sections are defined here, otherwise it could confuse the linker.

; if there are any issues with qemu breakpoint attaching, try steps in this order
; > just build
; cd tests
; > make payloads -B

; if that doesn't work, pray to alan turing and try again

%define HEADER_LOAD_ADDRESS 0x7C00+512
%define TMP_512_ADDR 0x7C00+512

extern nonfixed_read_hdr

global _entry
_entry:
    ; reset DS segment
    xor ax, ax
    mov ds, ax
    ; initialize stack
    mov ss, ax
    mov sp, STACK
    
    mov di,0
    mov es,ax ; ES:DI must be zeroed due to BIOS error with query int.

    mov [0x7C00+1], dl ; DRIVE NO.

    ; QUERY DRIVE PARAMETERS
    ;https://www.ctyme.com/intr/rb-0621.htm
    mov ah, 08h
    int 13h
    mov [0x7C00], cl ;0-5: SECTORS PER HEAD [i.e. 36 for a typical floppy]
                     ;6-7: MAX CYL UPPER BITS 

    inc dh ; by default, dh is the max head index, I want the head count
    mov [0x7C00+2], dh ; HEADS PER CYLINDER  [i.e. 2 for a typical floppy]

    ; es = 0x7C0, or memory address 0x7C00
    mov ax, 0x7C0
    mov es, ax


%if FIXED_LOAD == 0
    ; load second sector

    mov bp, 3
.tryagain2:
    push bp

    mov ax, 0201h
    mov cx, 0002h
    mov dl, [0x7C00+1] ; DRIVE NO.
    mov dh, 0
    mov bx, 512
    int 0x13
    pop bp

    cmp bp,0
    jne .skpchk2
    jc booterr
.skpchk2:
    jc .tryagain2
    dec bp

load_ii_done:
    jmp LOAD2ENTRY

%endif
global _aret
_aret:

    %if FIXED_LOAD == 1
    mov al, %FIXED_LOAD_INDEX
    %endif
    jmp _load_bootable
    


; ARGS:
; @param al - MBR index
_load_bootable:
%if FIXED_LOAD == 1
    ; load first sector
    mov ah,0
    shl al, 4
    add ax, 446
    mov bx, ax
%endif
    
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




%if FIXED_LOAD == 1
    mov dl, [0x7C00+1] ; drive num
    mov bx, 512
    ; es:bx = load segment
    mov ax, 0x0201 ; read sector op code / sector count

    int 0x13 ; sector interrupt
    jc booterr
%endif
%if FIXED_LOAD == 0
    jmp nonfixed_read_hdr
global nonfixed_read_hdr_ret
nonfixed_read_hdr_ret:

int 0x13 ; sector interrupt
jc booterr
%endif

    ; COPY HEADER DATA
    
    
    ; ENTRY SEGMENT: HEADER_LOAD_ADDRESS + 20
    ; LOAD_SEGMENT: HEADER_LOAD_ADDRESS + 22
    mov ax,[HEADER_LOAD_ADDRESS + 8]
    mov [0x7C00+28], ax   ; ENTRY SEGMENT 
    mov ax, [HEADER_LOAD_ADDRESS + 10]
    mov [0x7C00+30], ax  ; ENTRY OFFSET

    ;mov ax,[HEADER_LOAD_ADDRESS + 14]
    ;mov [0x7C00+6], ax   ; SECTOR COUNT [this can be ignored, the bootloader only sees the MBR start:end range]

    mov bx,[HEADER_LOAD_ADDRESS + 6]
    mov [0x7C00+8], bx   ; LOAD SEGMENT



    ;TODO:  SECTOR COMPARISON MUST BE FIXED TO SUPPORT LARGE DRIVES [where the hi cyl bits are stored in the sector count]
; load segment must be in BX before a jmp to next_read
.next_read:
.read_boundary_ret:

    mov dh, [0x7C00+18] ; dh = starting head
    mov al, [0x7C00+19] ; al = first sector
    mov cl, [0x7C00] ; SECTORS PER HEAD
    inc cl; sector indexing starts at 1, so al starts at 1
    sub cl,al ;cl=end_sector-first_sector (the max number of sectors that can be read)

    ; check: how many sectors can actually be read in this head?
    cmp dh, [0x7C00+21] ; cmp starting head with ending head
    jne .skip_sec_chk

    ;cmp starting cylinder with ending cylinder
    mov dh, [0x7C00+20] ; dh = starting cyl
    mov dl, [0x7C00+23] ; dl = ending cyl
    cmp dh, dl
    jne .skip_sec_chk

    ;starting_head == ending_head
    mov cl, [0x7C00+22] ;ending sector
    and cl, 0x3F
    mov al, [0x7C00+19] ;starting sector
    and al, 0x3F
    sub cl, al



.skip_sec_chk:

    and bx, 4095      ; bx %= 4096
    ; BX HOLDS SEGMENT COUNT mod 4096

    ;shr bx, 5
    ;mov ax, 127
    ;sub ax, bx
    mov ax, 4064
    sub ax,bx
    shr ax, 5
    mov dl, al ; ; DL now holds the sectors till next boundary

    cmp dl, 0
    je .read_boundary

; the disk controller cannot read across heads, and it can't read across 64kib boundaries.
    ; CL: sector count till next head, or until the end of the partition if that comes first.
    ; DL: sector count till boundary

    cmp cl, dl
    jl .clmin
        mov cl, dl
    .clmin:

    

    ; cl holds the min of dl, cl, the min readable sector count


    ; read sectors

    ; load address: [es:bx]
    ; es:bx
    mov es, [0x7C00 + 8] ; LOAD SEGMENT
    xor bx,bx; LOAD OFFSET
   

    push cx
    mov ah, 02
    mov al, cl ; number of sectors to read
    mov cx, [0x7C00+19] ;sector,cylinder
    mov dh, [0x7C00+18] ;head
    mov dl, [0x7C00+1] ;drive

    int 0x13
    jc booterr
    pop cx

    ; cl = sectors read
    mov [0x7C00+26], cl
     
    call _CL_inc_write_cur


    ; ARE THERE STILL MORE SECTORS?
    mov al, [0x7C00+21]
    cmp byte [0x7C00+18], al ; last_head == cur_head
    jne .read_continue
    mov ax, [0x7C00+22]
    cmp word [0x7C00+19], ax ; last_sec_and_cyl == cur_sec_and_cyl
    jne .read_continue

    jmp .read_done


.read_continue:

    mov bx, [0x7C00+8]
    jmp .next_read



.read_done:
    push word [0x7C00 + 28]   ; ENTRY SEGMENT
    push word [0x7C00 + 30]   ; ENTRY OFFSET

    retf ;ret far is the same as jmp far (but uses stack params)







.read_boundary:
    push cx
    ; read next sector from disk
    push es

    xor ax,ax 
    mov es,ax
    mov bx, TMP_512_ADDR

    mov ax, 0x0201 ; fcode / num sectors to read
    mov cx, [0x7C00+19] ;sector,cylinder
    mov dh, [0x7C00+18] ;head
    mov dl, [0x7C00+1] ;drive

    int 0x13
    jc booterr

    pop es

    ; copy to location
    mov cx, 512
    mov si, TMP_512_ADDR
    xor di,di

    cld
    rep movsb ; DS:(E)SI to ES:(E)DI.



    ; cl = sectors read
    mov cl,1
    mov [0x7C00+26], cl
    call _CL_inc_write_cur    


    pop cx
    mov bx, es
    jmp .read_boundary_ret


_CL_inc_write_cur:
 
    ; ADD SECTORS TO CHS ADDRESS AT 0x7C00+18
    add [0x7C00+19], cl
    mov cl, [0x7C00+19]
    and cl, 0x3F
    mov al, [0x7C00]
    and al, 0x3F
; max_sectors == cl?
    dec cl ; bc al is the sectors + 1
    cmp al, cl
    jne .skip_hd_inc

; reset cyl.
    mov cl, [0x7C00+19]
    and cl, ~0x3F
    inc cl ; sector indexing starts at 1
    mov [0x7C00+19],cl
; inc head
    inc byte [0x7C00+18]

; check if current_head == max_head
; if so, reset head to 0, and increment the cylinder
    mov al, [0x7C00+18]
    cmp [0x7C00+2], al
    jne .skip_cyl_inc

; if the cylinder reaches the maximum, forget it, no reason to check
; a boot error may occur, but it's the MBR's fault

    ;0x7C00+19 - 2 bytes SECTOR, CYLINDER OF STARTING ADDRESS

    mov byte [0x7C00+18], 0 ; reset head
    ; inc cyl
    add byte [0x7C00+20],1


.skip_cyl_inc:
.skip_hd_inc:


;  UPDATE LOAD SEGMENT
    ; THE NUMBER OF SEGMENTS TO ADD IS THE NUMBER OF SECTORS READ
    ; times 32, EQUIVALENT TO A SHL BY 5
    xor ch,ch
    mov cl, [0x7C00+26] ; SECTORS READ
    shl cx, 5
    add [0x7C00+8],cx
    ; the load segment must be in bx before a jmp to next_read
    mov es, [0x7C00+8]
    ret

global booterr
booterr:
    mov ax, 0x0E45
    int 0x10
    mov ax, 0x0E52
    int 0x10
    int 0x10
    cli
    hlt