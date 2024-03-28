.org 0x0
.text
.globl _idt,_gdt,_pg_dir,_tmp_floppy_area
_pg_dir:
.globl startup_32
startup_32:
  
  jmp after_page_tables

after_page_tables:
  pushl $0
  pushl $0
  pushl $0
  pushl $L6
  pushl $start
  jmp setup_paging
L6:
  jmp L6

setup_paging:
  ret
