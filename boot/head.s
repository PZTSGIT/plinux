.org 0x0
.text
.globl _idt,_gdt,_pg_dir,_tmp_floppy_area
_pg_dir:
.globl startup_32
startup_32:

#set data segments to gdt[10 >> 3]
  movl $0x10,%eax
  mov %ax,%ds
  mov %ax,%es
  mov %ax,%fs
  mov %ax,%gs  
  lss stack_start, %esp
  call _setup_idt
  call _setup_gdt

#reload segment registers
  movl $0x10,%eax
  mov %ax,%ds
  mov %ax,%es
  mov %ax,%fs
  mov %ax,%gs
  lss stack_start,%esp
  xorl %eax,%eax

#check a20 enabled
1:
  incl %eax
  movl %eax,0x000000
  cmpl %eax,0x100000
  je 1b

  movl %cr0,%eax
  andl $0x80000011,%eax
  orl $2,%eax
  movl %eax,%cr0
  call check_x87

  jmp after_page_tables

check_x87:
  fninit #initial FPU without checking for pending unmasked floating-point exception
  fstsw #store FPU status word after checking
  cmpb $0,%al
  je 1f
  movl %cr0,%eax
  xorl $6,%eax
  movl %eax,%cr0
  ret
.align 2
1:
  .byte 0xDB,0xE4
  ret

_setup_idt:
  lea ignore_int,%edx# load effective address
  movl $0x00080000,%eax
  movw %dx,%ax#eax contains segment selector and offset
  movw $0x8E00,%dx#?

  lea _idt,%edi
  mov $256,%ecx
rp_sidt:
  movl %eax,(%edi)
  movl %edx,4(%edi)
  addl $8,%edi
  dec %ecx
  jne rp_sidt
  lidt idt_descr
  ret

_setup_gdt:
  lgdt gdt_descr
  ret

.org 0x1000
pg0:

.org 0x2000
pg1:

.org 0x3000
pg2:

.org 0x4000
pg3:

.org 0x5000
_tmp_floppy_area:
  .fill 1024,1,0

after_page_tables:
  pushl $0
  pushl $0
  pushl $0
  pushl $L6
  pushl $start
  jmp setup_paging
L6:
  jmp L6

int_msg:
  .asciz "Unknown interrupt\n\r"

.align 2
ignore_int:
  pushl %eax
  pushl %ecx
  pushl %edx
  push %ds
  push %es
  push %fs
  movl $0x10,%eax
  mov %ax,%ds
  mov %ax,%es
  mov %ax,%fs
  pushl $int_msg
  #call _printk
  popl %eax
  pop %fs
  pop %es
  pop %ds
  popl %edx
  popl %ecx
  popl %eax
  iret

.align 2
setup_paging:
  movl $1024*5,%ecx
  xorl %eax,%eax
  xorl %edi,%edi

  cld;rep;stosl
  movl $pg0+7,_pg_dir
  movl $pg1+7,_pg_dir+4
  movl $pg2+7,_pg_dir+8
  movl $pg3+7,_pg_dir+12
  movl $pg3+4092,%edi
  movl $0xfff007,%eax
  std #set df flag 1, di will decrease
1:
  stosl #store eax at es:di
  subl $0x1000,%eax
  jge 1b
  xorl %eax,%eax
  movl %eax,%cr3 #cr3 is the address of PDE
  movl %cr0,%eax
  orl $0x80000000,%eax
  movl %eax,%cr0
  ret

.align 2
.word 0
idt_descr:
  .word 256*8 - 1
  .long _idt

.align 2
.word 0
gdt_descr:
  .word 256*8 - 1
  .long _gdt

_idt: .fill 256,8,0# repeat, size, value 

_gdt: .quad 0x0000000000000000
      .quad 0x00c09a0000000fff
      .quad 0x00c0920000000fff
      .quad 0x0000000000000000
      .fill 252,8,0
