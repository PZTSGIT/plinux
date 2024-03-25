SYSSIZE equ 0x3000
SETUPLEN equ 4				; nr of setup-sectors
BOOTSEG  equ 0x07c0			; original address of boot-sector
INITSEG  equ 0x9000			; we move boot here - out of the way
SETUPSEG equ 0x9020			; setup starts here
SYSSEG   equ 0x1000			; system loaded at 0x10000 (65536).
ENDSEG   equ SYSSEG + SYSSIZE		; where to stop loading
ROOT_DEV equ 0x306
[section .s16]
[BITS 16]
_start:
	mov	ax,BOOTSEG
	mov	ds,ax
	mov	ax,INITSEG
	mov	es,ax
	mov	cx,256
	sub	si,si
	sub	di,di
	rep 
	movsw
	jmp	INITSEG:go
go:
  mov DWORD ebx,gdt
  mov DWORD eax,[ebx]
  mov DWORD ecx,[ebx + 4]
  lgdt [gdt_48]
  push 0x1
  push 0x2
  push 0x3
  call pzt_func
  jmp $

pzt_func:
  push bp
  mov bp,sp
  push ax
  push bx
  push cx

  mov ax, [bp+4]
  mov bx, [bp+6]
  mov cx, [bp+8]

  pop cx
  pop bx
  pop ax
  pop bp
  ret 

gdt_48:
  dw 0x800
  dw 512+gdt, 0x9

gdt:
  ;dw 0x07ff
  ;dw 0x0000
  ;dw 0x9a00
  ;dw 0x00c0
  dw 0x1234
  dw 0x5678
  dw 0x9abc
  dw 0xdef0

times 510-($-$$) db 0
dw 0xaa55

