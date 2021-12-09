
pciide.o:     file format pe-i386


Disassembly of section .text:

00000000 <_inb>:
   0:	55                   	push   ebp
   1:	89 e5                	mov    ebp,esp
   3:	83 ec 14             	sub    esp,0x14
   6:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
   9:	66 89 45 ec          	mov    WORD PTR [ebp-0x14],ax
   d:	0f b7 45 ec          	movzx  eax,WORD PTR [ebp-0x14]
  11:	89 c2                	mov    edx,eax
  13:	ec                   	in     al,dx
  14:	88 45 ff             	mov    BYTE PTR [ebp-0x1],al
  17:	0f b6 45 ff          	movzx  eax,BYTE PTR [ebp-0x1]
  1b:	c9                   	leave  
  1c:	c3                   	ret    

0000001d <_outb>:
  1d:	55                   	push   ebp
  1e:	89 e5                	mov    ebp,esp
  20:	83 ec 08             	sub    esp,0x8
  23:	8b 55 08             	mov    edx,DWORD PTR [ebp+0x8]
  26:	8b 45 0c             	mov    eax,DWORD PTR [ebp+0xc]
  29:	66 89 55 fc          	mov    WORD PTR [ebp-0x4],dx
  2d:	88 45 f8             	mov    BYTE PTR [ebp-0x8],al
  30:	0f b6 45 f8          	movzx  eax,BYTE PTR [ebp-0x8]
  34:	0f b7 55 fc          	movzx  edx,WORD PTR [ebp-0x4]
  38:	ee                   	out    dx,al
  39:	90                   	nop
  3a:	c9                   	leave  
  3b:	c3                   	ret    

0000003c <_GetData>:
  3c:	55                   	push   ebp
  3d:	89 e5                	mov    ebp,esp
  3f:	83 ec 18             	sub    esp,0x18
  42:	8b 45 08             	mov    eax,DWORD PTR [ebp+0x8]
  45:	0f b6 c0             	movzx  eax,al
  48:	89 44 24 04          	mov    DWORD PTR [esp+0x4],eax
  4c:	c7 04 24 f8 0c 00 00 	mov    DWORD PTR [esp],0xcf8
  53:	e8 c5 ff ff ff       	call   1d <_outb>
  58:	c7 04 24 fc 0c 00 00 	mov    DWORD PTR [esp],0xcfc
  5f:	e8 9c ff ff ff       	call   0 <_inb>
  64:	0f b6 c0             	movzx  eax,al
  67:	89 45 fc             	mov    DWORD PTR [ebp-0x4],eax
  6a:	8b 45 fc             	mov    eax,DWORD PTR [ebp-0x4]
  6d:	c9                   	leave  
  6e:	c3                   	ret    

0000006f <_main>:
  6f:	55                   	push   ebp
  70:	89 e5                	mov    ebp,esp
  72:	83 e4 f0             	and    esp,0xfffffff0
  75:	83 ec 30             	sub    esp,0x30
  78:	e8 00 00 00 00       	call   7d <_main+0xe>
  7d:	c7 04 24 00 00 00 00 	mov    DWORD PTR [esp],0x0
  84:	e8 00 00 00 00       	call   89 <_main+0x1a>
  89:	c7 04 24 0a 00 00 00 	mov    DWORD PTR [esp],0xa
  90:	e8 00 00 00 00       	call   95 <_main+0x26>
  95:	c7 44 24 2c 00 00 00 	mov    DWORD PTR [esp+0x2c],0x0
  9c:	00 
  9d:	e9 a4 00 00 00       	jmp    146 <_main+0xd7>
  a2:	c7 44 24 28 00 00 00 	mov    DWORD PTR [esp+0x28],0x0
  a9:	00 
  aa:	e9 87 00 00 00       	jmp    136 <_main+0xc7>
  af:	c7 44 24 24 00 00 00 	mov    DWORD PTR [esp+0x24],0x0
  b6:	00 
  b7:	eb 71                	jmp    12a <_main+0xbb>
  b9:	8b 44 24 2c          	mov    eax,DWORD PTR [esp+0x2c]
  bd:	c1 e0 08             	shl    eax,0x8
  c0:	89 c2                	mov    edx,eax
  c2:	8b 44 24 28          	mov    eax,DWORD PTR [esp+0x28]
  c6:	c1 e0 03             	shl    eax,0x3
  c9:	09 d0                	or     eax,edx
  cb:	0b 44 24 24          	or     eax,DWORD PTR [esp+0x24]
  cf:	c1 e0 08             	shl    eax,0x8
  d2:	0d 00 00 00 f8       	or     eax,0xf8000000
  d7:	89 44 24 20          	mov    DWORD PTR [esp+0x20],eax
  db:	8b 44 24 20          	mov    eax,DWORD PTR [esp+0x20]
  df:	89 04 24             	mov    DWORD PTR [esp],eax
  e2:	e8 55 ff ff ff       	call   3c <_GetData>
  e7:	89 44 24 1c          	mov    DWORD PTR [esp+0x1c],eax
  eb:	81 7c 24 1c ff ff 00 	cmp    DWORD PTR [esp+0x1c],0xffff
  f2:	00 
  f3:	74 30                	je     125 <_main+0xb6>
  f5:	8b 44 24 24          	mov    eax,DWORD PTR [esp+0x24]
  f9:	89 44 24 0c          	mov    DWORD PTR [esp+0xc],eax
  fd:	8b 44 24 28          	mov    eax,DWORD PTR [esp+0x28]
 101:	89 44 24 08          	mov    DWORD PTR [esp+0x8],eax
 105:	8b 44 24 2c          	mov    eax,DWORD PTR [esp+0x2c]
 109:	89 44 24 04          	mov    DWORD PTR [esp+0x4],eax
 10d:	c7 04 24 10 00 00 00 	mov    DWORD PTR [esp],0x10
 114:	e8 00 00 00 00       	call   119 <_main+0xaa>
 119:	c7 04 24 0a 00 00 00 	mov    DWORD PTR [esp],0xa
 120:	e8 00 00 00 00       	call   125 <_main+0xb6>
 125:	83 44 24 24 01       	add    DWORD PTR [esp+0x24],0x1
 12a:	83 7c 24 24 07       	cmp    DWORD PTR [esp+0x24],0x7
 12f:	7e 88                	jle    b9 <_main+0x4a>
 131:	83 44 24 28 01       	add    DWORD PTR [esp+0x28],0x1
 136:	83 7c 24 28 1f       	cmp    DWORD PTR [esp+0x28],0x1f
 13b:	0f 8e 6e ff ff ff    	jle    af <_main+0x40>
 141:	83 44 24 2c 01       	add    DWORD PTR [esp+0x2c],0x1
 146:	83 7c 24 2c 63       	cmp    DWORD PTR [esp+0x2c],0x63
 14b:	0f 8e 51 ff ff ff    	jle    a2 <_main+0x33>
 151:	b8 00 00 00 00       	mov    eax,0x0
 156:	c9                   	leave  
 157:	c3                   	ret    
