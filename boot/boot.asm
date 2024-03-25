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
  mov cs,0x0002
  ;args: BX-load content to ES:BX
  mov bx,0x0200
  ;args: AH-kind of operation on disk(02 rep read sectors) AL-number of sectors need to be loaded
  mov ax,0x0200+SETUPLEN
  int 0x13 ;interupt in bios to load disk content to memory
  jnc ok_load_setup;jump near(in segment) if carry(CF)=0
  
  ;if failed, reset args and try again
  mov dx,0x0000
  mov ax,0x0000
  int 0x13
  jmp load_setup
