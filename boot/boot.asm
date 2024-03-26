;variable define
SYSSIZE equ 0x3000
SETUPLEN equ 4
BOOTSEG equ 0x07c0
INITSEG equ 0x9000
SETUPSEG equ 0x9020
SYSSEG equ 0x1000
ENDSEG equ SYSSEG + SYSSIZE

ROOT_DEV equ 0x306

;load first block to 0x90000
_start:
  mov ax,BOOTSEG
  mov ds,ax
  mov ax,INITSEG
  mov es,ax
  mov cx,0x100
  sub si,si
  sub di,di
  rep movsw
  jmp INITSEG:go

;change data/extra/stack segment and stack top position
go: 
  mov ax,cs
  mov ds,ax
  mov es,ax
  mov ss,ax
  mov sp,0xff00

;load 2-5 blocks which contains setup code to 0x90200
load_setup:
  ;args: DH-head DL-driver <0x80?floppy:hard
  mov dx,0x0000 
  ;args: CH-cylinder CL-sector
  mov cx,0x0002
  ;args: BX-load content to ES:BX
  mov bx,0x0200
  ;args: AH-kind of operation on disk(02 repr read sectors) AL-number of sectors need to be loaded
  mov ax,0x0200+SETUPLEN
  int 0x13 ;interupt in bios to load disk content to memory
  jnc ok_load_setup;jump near(in segment) if carry(CF)=0
  
  ;if failed, reset args and try again
  mov dx,0x0000
  mov ax,0x0000
  int 0x13
  jmp load_setup

ok_load_setup:
  ;get disk parameters
  ;args: DL-number of drivers
  mov dl,0x00
  ;args: AH-Kind of operation(8 repr read parametrs)
  mov ax,0x0800
  ;?args: BX-load to ES:BX, BX is 0x0200
  int 0x13
  ;return: BL-size, CX0-5-number of sectors, CX6-15:number of cylinder
  ; DH-head DL-number of drivers ES:DI=param address
  mov ch,0x00
  mov [sectors],cx;record number of sectors in a track
  mov es,ax ;0x13 change es, so reset

  mov ah,0x03
  xor bh,bh; page number
  int 0x10;ah=03 means read position of cursor
  ;return DL-row DH-column
  mov cx,24; repeat number
  mov bx,0x0007;args: BH-00 BL-07
  mov bp,msg1;address: es:bp
  ;args: DX row and column
  mov ax,0x1301;args: AH-13(show string) AL-01
  int 0x10;show string

  mov ax,SYSSEG
  mov es,ax;0x10000 to load system
  call read_it
  call kill_motor
  
  ;set root device
  mov ax, [root_dev]
  cmp ax,0
  jne root_defined

  mov bx,[sectors]
  mov ax,0x0208
  cmp bx,15
  je root_defined
  mov ax,0x021c
  cmp bx,18
  je root_defined
undef_root:
  jmp undef_root
root_defined:
  mov [root_dev], ax
  
  jmp SETUPSEG:0

read_it:
  mov ax,es
  test ax,0x0fff; AND, set SF,ZF,PF
die: jne die; 0-12 of es should be zero
  xor bx,bx
rp_read:
  mov ax,es
  cmp ax,ENDSEG; ENDSEG is 0x3000, means load 256 sectors
  jb ok1_read; jump below
  ret
ok1_read:
  mov ax,[sectors]; how much sectors in a track
  sub ax,[sread]
  mov cx,ax; how much sectors will be loaded first
  shl cx,9; cx << 9, for test boundary only
  add cx,bx; bx accumulate how many btyes are loaded in this segment 
  jnc ok2_read; jump if not carry (CF=0)(add)
  je ok2_read; jump if equal(ZF=1)
  ;if bytes being loaded will be out of boundary
  ;decrease the number of sectors (ax) will be loaded next
  xor ax,ax
  sub ax,bx
  shr ax,9; ax >> 9
ok2_read:
  call read_track; args: ax-number of sectors
  mov cx,ax
  add ax,[sread]
  cmp ax,[sectors]
  jne ok3_read; if a track have not been read completely
  mov ax,1
  sub ax,[head]
  jne ok4_read; if head = 0, jump to avoid increase track
  inc word [track]
ok4_read:
  mov [head],ax
  xor ax,ax
ok3_read:
  mov [sread],ax;how many sectors have been loaded in current track
  shl cx,9;cx<<9 is the number of bytes loaded in last read_track call
  add bx,cx; bx record how many bytes have been loaded in current segment
  jnc rp_read
  ;if current segment have loaded 64KB, deal with next 64K segment(ax=0x2000/0x3000), reset bx
  mov ax,es
  add ax,0x1000
  mov es,ax
  xor bx,bx
  jmp rp_read


;first entry&return: ax=0013h,bx=0,cx=13<<9,dx=?
read_track:
  ;backup regs
  push ax
  push bx
  push cx
  push dx
  ;backup regs
  mov dx, [track]
  mov cx, [sread]
  inc cx
  mov ch,dl
  mov dx, [head]
  mov dh,dl
  mov dl,0
  and dx,0x0100;head should be 0 or 1
  mov ah,2;read disk/al-sn/ch-cy/cl-s/dh-head/dl-floppy
  int 0x13
  jc bad_rt
  pop dx
  pop cx
  pop bx
  pop ax
  ret
bad_rt:
  mov ax,0
  mov dx,0
  int 0x13
  pop dx
  pop cx
  pop bx
  pop ax
  jmp read_track

;turn off floppy
kill_motor:
  push dx
  mov dx,0x3f2
  mov al,0
  out dx,ax
  pop dx
  ret
  
sread: dw 1+SETUPLEN; number of sectors having been loaded in current track
head: dw 0
track: dw 0 

sectors:
  dw 0; leave 4 bytes to record

msg1:
  db 13,10
  db "pzt learning linux"
  db 13,10,13,10

times 508 - ($-$$) db 0
root_dev:
  dw ROOT_DEV
boot_flag:
  dw 0xaa55
