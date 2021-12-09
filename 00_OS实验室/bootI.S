# filename - bootI.S
.intel_syntax
.globl start
#include "mmu.h"

.set PROT_MODE_CSEG, 0x08        # code segment selector
.set PROT_MODE_DSEG, 0x10        # data segment selector

start:
 .code16
  cli
  # Enable A20
  in al,0x92
  or al,0x2
  out 0x92,al
 
  # Load GDT
  lgdt [gdtdesc]
  # Switch from real to protected mode
  mov eax,cr0
  or  eax,1
  mov cr0,eax  
  
  # Jump into 32-bit protected mode
  #.byte 0xea
  #.word protcseg
  #.word 0x0008
  ljmp 0x0008,protcseg
  .code32
protcseg:
  mov  ax,0x0010
  mov  ds,ax
  mov  es,ax
  mov  fs,ax
  mov  gs,ax
  mov  ss,ax  
  mov  esp,offset start
  call _bootmain
spin:
  jmp  spin 
  .p2align 2
gdt:
  .long 0x00000000,0x00000000
  .long 0x0000ffff,0x00cf9a00
  .long 0x0000ffff,0x00cf9200

gdtdesc:
  .word gdtdesc - gdt - 1
  .long gdt
 


  
