IMAGE=a.img

AS86=nasm
CC=gcc
CFLAGS=-m32 -I.

DD = dd
DD_BS = 512
DFLAGS = conv=notrunc bs=$(DD_BS)
DD_1 = count=1 seek=0
DD_2_5 = count=4 seek=1
DD_6_ = count=256 seek=5 skip=8

LD = ld
LFLAGS=-e startup_32 -s -x -Ttext 0 -melf_i386
DEPS=boot/head.o init/main.o

all: $(IMAGE) 

#gcc -march=i386 -c init/main.c -o init/main.o -nostdinc -m32
#gcc -m32 -traditional -c boot/head.s -o boot/head.o
#ld boot/head.o init/main.o -m elf_i386 -e startup_32 -o bin/system -s -x -Ttext 0

$(IMAGE): boot/boot boot/setup bin/system
	$(DD) if=boot/boot of=$@ $(DD_1) $(DFLAGS)
	$(DD) if=boot/setup of=$@ $(DD_2_5) $(DFLAGS)
	$(DD) if=bin/system of=$@ $(DD_6_) $(DFLAGS)

boot/setup: boot/setup.asm
	$(AS86) $<

boot/boot: boot/boot.asm
	$(AS86) $< 

init/main.o: init/main.c
	$(CC) $(CFLAGS) -march=i386 -c $< -o $@ -nostdinc 

boot/head.o: boot/head.s
	$(CC) $(CFLAGS) -traditional -c $< -o $@

bin/system: $(DEPS) 
	$(LD) $(DEPS) $(LFLAGS) -o $@ 

clean:
	rm -f boot/boot
	rm -f boot/setup
	rm -f boot/head.o
	rm -f init/main.o
	rm -f bin/system
