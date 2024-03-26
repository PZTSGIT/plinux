AS86 = nasm
DD = dd

all: a.img

boot/boot: boot/boot.asm
	$(AS86) $< 

a.img: boot/boot
	$(DD) if=$< of=$@ bs=512 count=1 seek=0 conv=notrunc

clean:
	rm -f boot/boot
