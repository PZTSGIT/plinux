INITSEG equ 0x9000
SYSSEG equ 0x1000
SETUPSEG equ 0x9020

start:
  mov ax,INITSEG
  mov ds,ax
  mov ah,0x03
  xor bh,bh
  int 0x10
  mov [0], dx; get cursor position and save it in 0x90000

;get memory size
  mov ah,0x88
  int 0x15
  mov [2],ax

;get video-card data
  mov ah,0x0f
  int 0x10
  mov [4],bx;bh-display page
  mov [6],ax;al-video mode, ah-window width

;check for EGA/VGA and some config parameters
  mov ah,0x12
  mov bl,0x10
  int 0x10
  mov [8],ax
  mov [10],bx;bh-memory, bl-status
  mov [12],cx;parameters

;get hd0 data
  mov ax,0x0000
  mov ds,ax
  lds si,[4*0x41];load DS:SI with far pointer DS:[n] from memory, first two for si and other for ds
  mov ax,INITSEG
  mov es,ax
  mov di,0x0080
  mov cx,0x10
  rep
  movsb

;get hd1 data
  mov ax,0x0000
  mov ds,ax
  lds si,[4*0x46]
  mov ax,INITSEG
  mov es,ax
  mov di,0x0090
  mov cx,0x10
  rep
  movsb

;check
  mov ax,0x01500
  mov dl,0x81
  int 0x13
  jc no_disk1
  cmp ah,3
  je is_disk1
no_disk1:
  mov ax,INITSEG
  mov es,ax
  mov di,0x0090
  mov cx,0x10
  mov ax,0x00
  rep
  stosb 
is_disk1:
  
  cli

  mov ax,0x0000
  cld;di/si will increase when mov

;from 0x10000-0x90000 to 0x00000-0x80000
do_move:
  mov es,ax
  add ax,0x1000
  cmp ax,0x9000
  jz end_move
  mov ds,ax
  sub di,di
  sub si,si
  mov cx,0x8000
  rep movsw
  jmp do_move

end_move:
  mov ax,SETUPSEG
  mov ds,ax
  lidt [idt_48]
  lgdt [gdt_48]
  
;enable A20
  call empty_8042
  mov al,0xD1
  out 0x64,al
  call empty_8042
  mov al,0xdf
  out 0x60,al
  call empty_8042 

;set interupt
;it seems that send data to 0x20 and 0xa0 port will start to set iCW1-4
  mov al,0x11
  out 0x20,al
  dw 0x00eb,0x00eb
  out 0xa0,al
  dw 0x00eb,0x00eb

;start of hw int's 0x20
  mov al,0x20
  out 0x21,al
  dw 0x00eb,0x00eb

;start of hw int's 2 0x28
  mov al,0x28
  out 0xa1,al
  dw 0x00eb,0x00eb

;8259-1 master
  mov al,0x04
  out 0x21,al
  dw 0x00eb,0x00eb

;8259-2 slave
  mov al,0x02
  out 0xa1,al
  dw 0x00eb,0x00eb

;8086 mode
  mov al,0x01
  out 0x21,al
  dw 0x00eb,0x00eb
  out 0xa1,al
  dw 0x00eb,0x00eb

;mask off all interrupts for now
  mov al,0xff
  out 0x21,al
  dw 0x00eb,0x00eb
  out 0xa1,al 
  
  
;set protected mode and jump
  mov ax,0x0001
  lmsw ax; load machine status word
  jmp 8:0; 8>>3=1 goto second gdt, offset is 0


empty_8042:
  dw 0x00eb,0x00eb
  in al,0x64
  test al,2; al and 2, set SF,ZF,PF
  jnz empty_8042
  ret

gdt:
  dw 0,0,0,0
  
;gdt[1]
  dw 0x07ff
  dw 0x0000
  dw 0x9a00
  dw 0x00c0

;gdt[2]
  dw 0x07ff
  dw 0x0000
  dw 0x9200
  dw 0x00c0

idt_48:
  dw 0
  dw 0,0

gdt_48:
  dw 0x800
  dw 512+gdt, 0x9
