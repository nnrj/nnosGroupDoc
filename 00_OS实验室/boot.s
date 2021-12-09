.set PROT_MODE_CSEG, 0x08        # code segment selector
.set PROT_MODE_DSEG, 0x10        # data segment selector

.globl start
start:
.code16
  # close CPU interrupt
  cli
  # clear screen
  movb  $0x06,	%ah
  movb  $0x00,	%al		# roll up all rows, clear the screen
  movb  $0x00,	%ch		# row of left top corner
  movb  $0x00,	%cl		# col of left top corner
  movb  $0x18,	%dh		# row of right bottom corner
  movb  $0x4f,	%dl		# col of right bottom corner
  movb  $0x07,	%bh		# property of roll up rows
  int	$0x10
  # Enable A20
  inb   $0x92,  %al
  orb   $0x2,   %al
  outb  %al,    $0x92

  # Load GDT
  lgdt  gdt_ptr

  # Switch from real to protected mode
  movl  %cr0,   %eax
  orl   $0x1,   %eax
  movl  %eax,   %cr0

  # Jump into 32-bit protected mode
  ljmpl $0x08,  $protcseg

.code32
protcseg:
  movw  $0x10,  %ax
  movw  %ax,    %ds
  movw  %ax,    %es
  movw  %ax,    %fs
  movw  %ax,    %gs
  movw  %ax,    %ss
  movl  $start, %esp  
 
  # 根据FAT32的数据结构填写文件的开始扇区数
  movl  $0x2020,%eax
  movl  $0x70000,%ebx
  movl  $200,%ecx  
  call  rd_disk_m_32
  # 以上4行代码不能删除删除后系统无限重启动，因为这部分代码只是读取ELF文件到缓冲区，我的代码是二进制代码无需解析ELF
  # 并且代码也已经跟在汇编代码后面。  
  call  setup_page
  sgdt  gdt_ptr	
  movl  (gdt_ptr+0x2),%ebx
  orl   $0xc0000000,(0x10+4)(%ebx)
  addl  $0xc0000000,(gdt_ptr+2)
  addl  $0xc0000000,%esp
  movl  $0x00200000,%eax
  movl  %eax,       %cr3
  movl  %cr0,       %eax
  orl   $0x80000000,%eax
  movl  %eax,       %cr0 
  lgdt  gdt_ptr	
  movb  $'p',   %ds:0xb800e
  movb  $0x0c,  %ds:0xb800f
  ljmpl $0x08,  $enter_kernel

enter_kernel:
  # 如果是加载ELF文件则调用kernel_init函数解析ELF文件
  #call  kernel_init
  # 直接解析二进制内核文件,解析ELF文件的代码在kernel_init  
  # 挪动C内核到0x10000处并从这里开始运行C内核
  movl  $512*1024/4,%ecx
  pushl %ecx
  # 先压入第三个参数要拷贝的内存的大小
  movl  $_kernel_main,%esi
  pushl %esi
  # 再压入第二个参数源地址
  movl  $0x10000,%edi
  pushl %edi
  # 最后压入第一个参数目的地址顺序是从右往左压入  
  call  mem_cpy
  # 该函数在打开分页模式后由于只映射了1兆以内内存所以无法将该代码拷贝到高于1兆的内存，表现为无限重启动。
  # 由调用者清理栈中的参数
  addl  $12,%esp
  movl  $0xc0010000+_kernel_main,%ebx  
  movl  %ebx,%esp 
  #movl  $0xc009f000,%esp
  # 开始执行C内核文件，但有问题表现为不停的重启动，似乎是分页代码导致 
  call  _kernel_main 
  #movl  $0xc009f000,%esp
  #jmp   0xc0000743
  # 将c内核的BIN文件加载到0xc0001500处
  
  #jmp   0x1500
  # 以下代码移植于操作系统真相还原在汇编层面可以分页，并正常显示字符P
kernel_init:
  # 内核加载在0x70000处
  xorl  %eax,%eax
  xorl  %ebx,%ebx
  xorl  %ecx,%ecx
  xorl  %edx,%edx
  movw  0x7002a,%dx
  movl  0x7001c,%ebx
  addl  $0x70000,%ebx
  movw  0x7002c,%cx	
.each_segment:
  cmpb  $0x0,(%ebx)
  je    .PTNULL
  pushl 0x10(%ebx)
  movl  0x4(%ebx),  %eax
  addl  $0x70000,   %eax
  pushl %eax
  pushl 0x8(%ebx)
  call  mem_cpy
  addl  $0xc,%esp

.PTNULL:
  addl  %edx,%ebx
  loop  .each_segment
  ret    
  # 该函数修改自操作系统真相还原，增加几个保存寄存器地址的代码并且先按4字节拷贝，剩余的按单字节拷贝这样效率最高。
mem_cpy:
  cld    
  pushl %ebp
  movl  %esp,%ebp
  pushl %esi
  pushl %edi
  pushl %ecx
  movl  0x8(%ebp),  %edi
  movl  0xc(%ebp),  %esi
  movl  0x10(%ebp), %ecx
  shr   $2,%ecx  
  rep   movsw
  movl  0x10(%ebp),%ecx
  andl  $3,%ecx
  rep   movsb  
  popl  %ecx
  popl  %edi
  popl  %esi
  popl  %ebp
  ret   	


setup_page:	
  # 页目录占用空间清零
  movl  $4096,      %ecx
  movl  $0x0,       %esi
.clear_page_dir:
  movb  $0x0,0x00200000(%esi)
  inc   %esi
  loop  .clear_page_dir	
	
  # 创建页目录表
.create_pde:
  movl  $0x100000,  %eax
  addl  $0x1000,    %eax
  movl  %eax,       %ebx 
  orl   $0x07,      %eax
  movl  %eax,       (0x00200000+0x000)
  movl  %eax,       (0x00200000+0xc00)
  subl  $0x1000,    %eax
  movl  %eax,       (0x00200000+4092)
  movl  $4096,      %ecx
  movl  $0,         %esi
  movl  $0x07,      %edx 
  # 创建页表	
.create_pte:
  movl  %edx,       (%ebx,%esi,4)
  addl  $4096,      %edx 
  incl  %esi
  loop  .create_pte
  # 创建内核的其他页表
  movl  $0x00200000,  %eax
  addl  $0x2000,    %eax
  orl   $0x07,      %eax
  movl  $0x00200000,  %ebx
  movl  $254,       %ecx
  movl  $769,       %esi
.create_kernel_pde:
  movl  %eax,       (%ebx,%esi,4)
  incl  %esi
  addl  $0x1000,    %eax
  loop  .create_kernel_pde
  ret	
  # 32位保护模式下硬盘lba方式读取硬盘扇区，无法运行于物理机下，虚拟机可以正常运行  
rd_disk_m_32:
  movl  %eax,%esi
  movw  %cx,%di
  movw  $0x1f2,%dx
  movb  %cl,%al
  outb  %al,(%dx)  
  movl  %esi,%eax
  movw  $0x1f3,%dx
  outb  %al,(%dx)
  movb  $0x8,%cl
  shr   %cl,%eax
  movw  $0x1f4,%dx
  outb  %al,(%dx)
  shr   %cl,%eax
  movw  $0x1f5,%dx
  outb  %al,(%dx)
  shr   %cl,%eax
  andb  $0xf,%al
  orb   $0xe0,%al
  movw  $0x1f6,%dx
  outb  %al,(%dx)
  movw  $0x1f7,%dx
  movb  $0x20,%al
  outb  %al,(%dx)

.not_ready:
  nop
  inb   (%dx),%al
  andb  $0x88,%al
  cmpb  $0x8,%al
  jne   .not_ready
  movw  %di,%ax
  movw  $0x100,%dx
  mulw  %dx
  movw  %ax,%cx
  movw  $0x1f0,%dx

.go_on_read:
  inw   (%dx),%ax
  movw  %ax,(%ebx)
  addl  $0x2,%ebx
  loop  .go_on_read
  ret      

  hlt
  # 强制4字节对齐
.p2align 2
  # gdt表
gdt:
  .quad 0x0000000000000000 # 空描述符
  .quad 0x00cf98000000ffff # 内核的CODE段描述符
  .quad 0x00cf92000000ffff # 内核的DATA段描述符
  .quad 0x00cffa000000ffff # 用户的CODE段描述符
  .quad 0x00cff2000000ffff # 用户的DATA段描述符

gdt_ptr:
  .word gdt_ptr - gdt - 1
  .long gdt
  # C代码将会被链接到这里链接地址是0X10000
_kernel_main:  
