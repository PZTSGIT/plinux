;mov ax,0x07c0
;mov ds,ax
;mov ax,0x9000
;mov es,ax
;mov cx,256
;sub si,si
;sub di,di
;rep movsw
;
;times 510-($-$$) db 0
;dw 0xaa55

mov ax, 0x07c0
db $
mov ax, 07c0h
db $
org 508
dw 0xaa55
