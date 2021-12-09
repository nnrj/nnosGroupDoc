############################################################
#
#       fat32������������
#       ����:��������
#       QQ:1063997396
#       ˵����
#           ��δ����ǲο����ϵĴ��룬Դ������intel�﷨��
#           ���޸�ΪAT&T�﷨����
#           ��һ���ѧϰŶ������������
#############################################################
.code16
.globl _start
_start:

jmp start
#.fill 0x5a-3,1,0  # ���dbr
.byte 0x6D,0x6B,0x66,0x73,0x2E,0x66,0x61,0x74,0x00,0x02,0x08,0x20,0x00,0x02,0x00,0x00,0x00,0x00,0xF8,0x00,0x00,0x20,0x00,0x40,0x00,0x00,0x00,0x00,0x00,0xF0,0x5D,0x09,0x00,0x57,0x02,0x00,0x00,0x00,0x00,0x00,0x00,0x02,0x00,0x00,0x00,0x01,0x00,0x06,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x01,0x29,0x96,0x2E,0xE7,0x9F,0x4E,0x4F,0x20,0x4E,0x41,0x4D,0x45,0x20,0x20,0x20,0x20,0x46,0x41,0x54,0x33,0x32,0x20,0x20,0x20
m_bsldrmiss:
.asciz "BSLDR missing.\r\n"
bsldr:
.ascii "BSLDR      "

.equ BOOTSEG,0x0000
.equ BOOTOFF,0x7c00
.equ TMPSEG,0x1000  
.equ TMPOFF,0x0000
.equ BOOTDRIVER,0x80  

LBA:                 
SIZE:		.byte 16						
RESERVED:	.byte 0						
COUNT:		.word 0x0001					
BUFFER:		.long TMPSEG				
SECTORNUML:	.long 0						
SECTORNUMH:	.long 0



# ��ʾ�ַ���
PRINT:   
P_START:
lodsb
orb %al,%al
jz RETURN
call DIS_CHAR
jmp P_START
RETURN:
ret
# ��ʾһ���ַ�
DIS_CHAR:
movb $0x0e,%ah
int $0x10
ret

# int 0x13 �� 0x42 �Ź��ܴӴ��̶� n �� sectors �� buffer ��
LOAD:
LOAD_START:
movl %eax,SECTORNUML
movl %ecx,BUFFER
movb $0x42,%ah
movb $0x80,%dl
movw $LBA,%si
int $0x13
jc LOAD_START
ret

# ++++++++++++++++++++++++++++++
start:
movw $BOOTSEG,%ax
movw %ax,%ds
movw %ax,%es
movw %ax,%ss
movw $0x7c00,%bp	
movw $0x7c00,%sp


movw BOOTOFF+510,%ax
cmpw $0xaa55,%ax
jz find_bts

L1:		
jmp L1	
find_bts:

find_fat32:

movw BOOTOFF+0x0b,%ax	# bp-2  ÿ�����ֽ��� 2�ֽ�
pushw %ax
movb BOOTOFF+0x0d,%al	# bp-2-2=bp-4  ÿ�������� 1
xorb %ah,%ah
pushw %ax

xorl %eax,%eax
movw BOOTOFF+0x0e,%ax	# ����������Ŀ
#addw $63,%ax
pushl %eax				# bp-2-2-4=bp-8   FAT��ʼ���� 4
movl %eax,%ecx
movl BOOTOFF+0x24,%eax	# FAT��������
shll $1,%eax
addl %ecx,%eax
pushl %eax				# bp-2-2-4-4=bp-12  FAT���ݿ�ʼ���� 4
movl BOOTOFF+0x2c,%eax	# ��Ŀ¼�غ�

search_rootdir:
pushl %eax

call GET_SECT_FROM_CLUST	# search for bsldr in fat32

movl %eax,SECTORNUML	# eaxΪ��Ŀ¼��������
xorl %eax,%eax
movb -4(%bp),%al
movw %ax,COUNT

movl $(TMPSEG),BUFFER
movb $0x42,%ah
movb $0x80,%dl
movw $LBA,%si
int $0x13

movw $(TMPSEG),%ax
movb -4(%bp),%dl
shlw $9,%dx		# *512
addw %ax,%dx	# *512+TMPSEG upper limit


find_bsldr:		# �ڱ���������
movw $bsldr,%si
movw %ax,%di	# TMPSEG
movw $11,%cx
repe cmpsb
jz get_bsldr
addw $0x20,%ax
cmpw %dx,%ax
jbe find_bsldr
# ׼������һ��������
popl %eax
call GET_NEXT_CLUST
cmpl $0xffffffff,%eax
jnz search_rootdir	#���������еĸ�Ŀ¼!
movw $m_bsldrmiss,%si
call PRINT
L2:
jmp L2	

get_bsldr:


## �����ļ�����ת��0x7e00
movw %ax,%bx	#����Ŀ¼������
movw 0x14(%bx),%ax	# �ļ���ʼ�غŵĸ�16 λ
pushw %ax
movw 0x1a(%bx),%ax	# �ļ���ʼ�غŵĵ�16 λ
pushw %ax
popl %eax
xorl %ebx,%ebx
movw -4(%bp),%bx
movw %bx,COUNT
movl $0x7e00,%ecx

load_bsldr:
pushl %ecx
pushl %eax

call GET_SECT_FROM_CLUST

call LOAD
popl %eax

call GET_NEXT_CLUST
popl %ecx	# get_next_clust�ƻ���ecx

cmpl $0x0fffffff,%eax
jz load_ok

xorl %edx,%edx
movw -4(%bp),%dx
shll $9,%edx

addl %edx,%ecx
jmp load_bsldr

load_ok:
ljmp $0,$0x7e00
 
# ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;������
GET_NEXT_CLUST:		#������һ���غ�
pushl %ecx
shll $2,%eax
xorl %edx,%edx
xorl %ebx,%ebx
movw -2(%bp),%bx		# 512
divl %ebx
pushl %edx
addl -8(%bp),%eax	#  eax=eax*4/512+[bp-8] ; edx(ebx)=eax*4%512

movl $TMPSEG,%ecx
call LOAD

popl %ebx	# ebx=edx=�غ�ƫ��
movl TMPSEG(%bx),%eax
popl %ecx
ret
 

GET_SECT_FROM_CLUST:	# ����غŶ�Ӧ����������
subl $2,%eax
xorl %ebx,%ebx
movb -4(%bp),%bl
mull %ebx
addl -12(%bp),%eax	#first cluster in data: eax=(eax-2)*[bp-4]+[bp-12]
ret 
    
	.org  0x200-2
    .word 0xAA55
