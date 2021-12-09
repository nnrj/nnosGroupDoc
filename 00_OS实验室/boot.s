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
 
  # ����FAT32�����ݽṹ��д�ļ��Ŀ�ʼ������
  movl  $0x2020,%eax
  movl  $0x70000,%ebx
  movl  $200,%ecx  
  call  rd_disk_m_32
  # ����4�д��벻��ɾ��ɾ����ϵͳ��������������Ϊ�ⲿ�ִ���ֻ�Ƕ�ȡELF�ļ������������ҵĴ����Ƕ����ƴ����������ELF
  # ���Ҵ���Ҳ�Ѿ����ڻ�������档  
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
  # ����Ǽ���ELF�ļ������kernel_init��������ELF�ļ�
  #call  kernel_init
  # ֱ�ӽ����������ں��ļ�,����ELF�ļ��Ĵ�����kernel_init  
  # Ų��C�ں˵�0x10000���������￪ʼ����C�ں�
  movl  $512*1024/4,%ecx
  pushl %ecx
  # ��ѹ�����������Ҫ�������ڴ�Ĵ�С
  movl  $_kernel_main,%esi
  pushl %esi
  # ��ѹ��ڶ�������Դ��ַ
  movl  $0x10000,%edi
  pushl %edi
  # ���ѹ���һ������Ŀ�ĵ�ַ˳���Ǵ�������ѹ��  
  call  mem_cpy
  # �ú����ڴ򿪷�ҳģʽ������ֻӳ����1�������ڴ������޷����ô��뿽��������1�׵��ڴ棬����Ϊ������������
  # �ɵ���������ջ�еĲ���
  addl  $12,%esp
  movl  $0xc0010000+_kernel_main,%ebx  
  movl  %ebx,%esp 
  #movl  $0xc009f000,%esp
  # ��ʼִ��C�ں��ļ��������������Ϊ��ͣ�����������ƺ��Ƿ�ҳ���뵼�� 
  call  _kernel_main 
  #movl  $0xc009f000,%esp
  #jmp   0xc0000743
  # ��c�ں˵�BIN�ļ����ص�0xc0001500��
  
  #jmp   0x1500
  # ���´�����ֲ�ڲ���ϵͳ���໹ԭ�ڻ�������Է�ҳ����������ʾ�ַ�P
kernel_init:
  # �ں˼�����0x70000��
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
  # �ú����޸��Բ���ϵͳ���໹ԭ�����Ӽ�������Ĵ�����ַ�Ĵ��벢���Ȱ�4�ֽڿ�����ʣ��İ����ֽڿ�������Ч����ߡ�
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
  # ҳĿ¼ռ�ÿռ�����
  movl  $4096,      %ecx
  movl  $0x0,       %esi
.clear_page_dir:
  movb  $0x0,0x00200000(%esi)
  inc   %esi
  loop  .clear_page_dir	
	
  # ����ҳĿ¼��
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
  # ����ҳ��	
.create_pte:
  movl  %edx,       (%ebx,%esi,4)
  addl  $4096,      %edx 
  incl  %esi
  loop  .create_pte
  # �����ں˵�����ҳ��
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
  # 32λ����ģʽ��Ӳ��lba��ʽ��ȡӲ���������޷�������������£������������������  
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
  # ǿ��4�ֽڶ���
.p2align 2
  # gdt��
gdt:
  .quad 0x0000000000000000 # ��������
  .quad 0x00cf98000000ffff # �ں˵�CODE��������
  .quad 0x00cf92000000ffff # �ں˵�DATA��������
  .quad 0x00cffa000000ffff # �û���CODE��������
  .quad 0x00cff2000000ffff # �û���DATA��������

gdt_ptr:
  .word gdt_ptr - gdt - 1
  .long gdt
  # C���뽫�ᱻ���ӵ��������ӵ�ַ��0X10000
_kernel_main:  
