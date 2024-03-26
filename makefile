IMAGE = a.img

AS86 = nasm

DD = dd
DD_BS = 512
DD_FLAGS = conv=notrunc bs=$(DD_BS)
DD_1 = count=1 seek=0
DD_2_5 = count=4 seek=1

all: $(IMAGE) 

$(IMAGE): boot/boot boot/setup
	$(DD) if=boot/boot of=$@ $(DD_1) $(DD_FLAGS)
	$(DD) if=boot/setup of=$@ $(DD_2_5) $(DD_FLAGS)

boot/setup: boot/setup.asm
	$(AS86) $<

boot/boot: boot/boot.asm
	$(AS86) $< 

clean:
	rm -f boot/boot
	rm -f boot/setup
