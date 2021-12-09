	.file	"pciide.c"
	.intel_syntax noprefix
	.text
	.def	_inb;	.scl	3;	.type	32;	.endef
_inb:
	push	ebp
	mov	ebp, esp
	sub	esp, 20
	mov	eax, DWORD PTR [ebp+8]
	mov	WORD PTR [ebp-20], ax
	movzx	eax, WORD PTR [ebp-20]
	mov	edx, eax
/APP
 # 12 "pciide.c" 1
	.byte 0xec	
 # 0 "" 2
/NO_APP
	mov	BYTE PTR [ebp-1], al
	movzx	eax, BYTE PTR [ebp-1]
	leave
	ret
	.def	_outb;	.scl	3;	.type	32;	.endef
_outb:
	push	ebp
	mov	ebp, esp
	sub	esp, 8
	mov	edx, DWORD PTR [ebp+8]
	mov	eax, DWORD PTR [ebp+12]
	mov	WORD PTR [ebp-4], dx
	mov	BYTE PTR [ebp-8], al
	movzx	eax, BYTE PTR [ebp-8]
	movzx	edx, WORD PTR [ebp-4]
/APP
 # 20 "pciide.c" 1
	.byte 0xee
 # 0 "" 2
/NO_APP
	nop
	leave
	ret
	.globl	_GetData
	.def	_GetData;	.scl	2;	.type	32;	.endef
_GetData:
	push	ebp
	mov	ebp, esp
	sub	esp, 24
	mov	eax, DWORD PTR [ebp+8]
	movzx	eax, al
	mov	DWORD PTR [esp+4], eax
	mov	DWORD PTR [esp], 3320
	call	_outb
	mov	DWORD PTR [esp], 3324
	call	_inb
	movzx	eax, al
	mov	DWORD PTR [ebp-4], eax
	mov	eax, DWORD PTR [ebp-4]
	leave
	ret
	.def	___main;	.scl	2;	.type	32;	.endef
	.section .rdata,"dr"
LC0:
	.ascii "Bus#\11Dev#\11Func#\0"
LC1:
	.ascii "%2.2x\11%2.2x\11%2.2x\11\0"
	.text
	.globl	_main
	.def	_main;	.scl	2;	.type	32;	.endef
_main:
	push	ebp
	mov	ebp, esp
	and	esp, -16
	sub	esp, 48
	call	___main
	mov	DWORD PTR [esp], OFFSET FLAT:LC0
	call	_printf
	mov	DWORD PTR [esp], 10
	call	_putchar
	mov	DWORD PTR [esp+44], 0
	jmp	L7
L13:
	mov	DWORD PTR [esp+40], 0
	jmp	L8
L12:
	mov	DWORD PTR [esp+36], 0
	jmp	L9
L11:
	mov	eax, DWORD PTR [esp+44]
	sal	eax, 8
	mov	edx, eax
	mov	eax, DWORD PTR [esp+40]
	sal	eax, 3
	or	eax, edx
	or	eax, DWORD PTR [esp+36]
	sal	eax, 8
	or	eax, -134217728
	mov	DWORD PTR [esp+32], eax
	mov	eax, DWORD PTR [esp+32]
	mov	DWORD PTR [esp], eax
	call	_GetData
	mov	DWORD PTR [esp+28], eax
	cmp	DWORD PTR [esp+28], 65535
	je	L10
	mov	eax, DWORD PTR [esp+36]
	mov	DWORD PTR [esp+12], eax
	mov	eax, DWORD PTR [esp+40]
	mov	DWORD PTR [esp+8], eax
	mov	eax, DWORD PTR [esp+44]
	mov	DWORD PTR [esp+4], eax
	mov	DWORD PTR [esp], OFFSET FLAT:LC1
	call	_printf
	mov	DWORD PTR [esp], 10
	call	_putchar
L10:
	add	DWORD PTR [esp+36], 1
L9:
	cmp	DWORD PTR [esp+36], 7
	jle	L11
	add	DWORD PTR [esp+40], 1
L8:
	cmp	DWORD PTR [esp+40], 31
	jle	L12
	add	DWORD PTR [esp+44], 1
L7:
	cmp	DWORD PTR [esp+44], 99
	jle	L13
	mov	eax, 0
	leave
	ret
	.ident	"GCC: (GNU) 7.4.0"
	.def	_printf;	.scl	2;	.type	32;	.endef
	.def	_putchar;	.scl	2;	.type	32;	.endef
