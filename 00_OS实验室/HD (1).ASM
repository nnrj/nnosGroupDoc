;程序清单: hd.asm(实模式下的硬盘DMA)
.386P
outx        MACRO   Reg, Val    ; 向Reg端口写入数据Val
            mov     dx, Reg
            mov     al, Val
            out     dx, al
            ENDM
inx         MACRO   Reg         ; 从Reg端口读入数据, 存放在AL中
            mov     dx, Reg
            in      al, dx
            ENDM           

EchoCh      MACRO   ascii
            mov     ah,2
            mov     dl,ascii
            int     21h
            ENDM
            org     100h
CSEG        SEGMENT USE16           ;1代码段
            ASSUME  CS:CSEG,DS:CSEG,SS:CSEG
_START:
            JMP     NEAR PTR BEGIN
CfgSpace    DB      256 DUP(0)      ;PCI设备的256字节配置空间
bus         DW      0               ;bus号,0~255
dev         DW      0               ;dev号,0~31
func        DW      0               ;func号,0~7
index       DW      0               ;index,0~63
;----------------------------------------------------------------------------
;BMCRA       EQU     18b0h
BMCRA       EQU     0C00H
numSect     EQU     1            ; 读取1个扇区
lbaSector   EQU     0            ; LBA=0
BMCMD_REG   EQU     0            ; 主控命令寄存器的偏移
BMSTA_REG   EQU     2            ; 主控状态寄存器的偏移
BMPRD_REG   EQU     4            ; 物理区域描述符指针寄存器的偏移
piobasea1   EQU     01F0H        ; ATA设备控制块寄存器基地址
pioBasea2   EQU     03F0H        ; ATA命令命令块寄存器基地址
;-----------------------------------------------------------------------------
ALIGN 2                       
_Buffer     db      512*numSect dup (0)   ; 内存缓冲区
_BufferLen  equ     $-_Buffer
ALIGN 4                       
prdBuf      dd      0           ; 物理区域描述符
            dd      0
prdBufAddr  dd      0           ; 物理区域描述符地址
bufferaddr  dd      0           ; 内存缓冲区地址
;-----------------------------------------------------------------------------
BEGIN:
            mov     ax,CSEG
            ;XOR     AX,AX
            mov     ds,ax           ;ds指向数据段
            mov     es,ax           ;es指向数据段
            MOV     SS,AX
            call    FindPCIIDE      ;搜索PCI-IDE设备
            lea     si,CfgSpace     ;显示配置空间中的256字节数据
            MOV     EAX,DWORD PTR [SI+20H]      ; 把基地寄存器寄存器的地址放到EAX寄存器里
            SUB     AX,1
            MOV     WORD PTR DS:[BMCRA],AX      ; 把AX寄存器的内容赋值BMCRA
            mov     bx,16
            mov     ax,ds
            mul     bx                      ; 计算并设置数据段基址
            add     ax, offset prdBuf       ; 数据段基址+offset prdBuf
            adc     dx, 0                   ; dx:ax = prdBuf的物理地址
            mov     WORD PTR prdBufAddr, ax
            mov     WORD PTR prdBufAddr+2, dx
            mov     ax,ds
            mul     bx
            add     ax, offset _Buffer      ; 段基址+offset _Buffer
            adc     dx, 0                   ; dx:ax = _Buffer的物理地址
            mov     WORD PTR bufferaddr, ax
            mov     WORD PTR bufferaddr+2, dx
            cli                             ; 关中断
            
            call    ReadSectors             ; DMA方式读取硬盘扇区
            sti                             ; 允许中断
            call    ShowBuffer              ; 显示缓冲区内容
            mov     ax,4c00h
            int     21h
            
; 搜索PCI-IDE设备, 获取PCI配置空间
FindPCIIDE:  
            mov     bus, 0          ; bus号从0循环到255
loop_bus:                
            mov     dev, 0          ; dev号从0循环到31
loop_dev:               
            mov     func, 0         ; func号从0循环到7
loop_func:                
            mov     index, 0        ; index号从0循环到63
loop_index:
            ;构造eax为一个32位双字, 写入0cf8h端口
            ;(1 << 31)|(bus << 16)|(dev << 11)|(func << 8)|(index << 2)
            movzx   eax,bus         ;eax=bus               
            movzx   ebx,dev         ;ebx=dev               
            movzx   ecx,func        ;ecx=func
            movzx   edx,index       ;dex=index
            shl     eax,16          ;eax=(bus<<16)
            shl     ebx,11          ;ebx=(dev<<11)
            shl     ecx,8           ;ecx=(func<<8)
            shl     edx,2           ;edx=(index<<2)
            or      eax,80000000h   ;eax=(1<<31)||(bus<<16)
            or      eax,ebx         ;eax=..||(dev << 11)
            or      eax,ecx         ;eax=..||(func << 8)
            or      eax,edx         ;eax=..||(index << 2)
            ;从0cf8h端口读取的配置寄存器将保存在CfgSpace[index*4]中
            lea     edi,CfgSpace[edx]
            mov     dx,0cf8h
            out     dx,eax          ;eax写入到0cf8h端口
            mov     dx,0cfch
            in      eax,dx          ;从0cfch端口读入         
            cld
            stosd                   ;配置寄存器保存在CfgSpace中                       
            inc     index
            cmp     index, 64
            jb      loop_index      ;index=0~63
            cmp     WORD PTR CfgSpace[0ah],0101h    ;检查类代码寄存器
            jz      FindValidOne    ;BaseClass=01h,Sub-Class=01h                            
            cmp     func,0          ;func=0时,检查为多功能设备
            jnz     NotFunc0        ;func=1时,不检查
            test    CfgSpace[0eh],80h   ;Bit7=1,<bus,dev>是多功能设备
            jz      NotMultiFunc    ;Bit7=0,不是
NotFunc0:
            inc     func
            cmp     func, 8
            jb      loop_func       ;index=0~7
NotMultiFunc:
            inc     dev
            cmp     dev, 32
            jb      loop_dev        ;dev=0~31
            inc     bus
            cmp     bus, 256
            jb      loop_bus        ;bus=0~255             
FindValidOne:
            ret
;FindPCIIDE  ENDP
; 检查ATA状态寄存器, 直到BSY=0和DRQ=0
waitDeviceReady     proc
waitReady:
            inx     piobasea1+7    ; 读取ATA状态寄存器
            and     al, 10001000b       ; BSY=1或DRQ=1,继续查询
            jnz     waitReady
            ret
waitDeviceReady endp
; 采用DMA方式读取硬盘扇区
ReadSectors proc              
            ; Start/Stop=0, 停止以前的DMA传输
            outx    bmcra+BMCMD_REG, 00h
            ; 清除主控状态寄存器的Interrupt和Error位
            outx    bmcra+BMSTA_REG, 00000110b
            ; 建立一个物理区域描述符
            mov     eax, bufferaddr
            mov     prdBuf, eax                   ; Physical Address
            mov     word ptr prdBuf+4, _BufferLen ; Byte Count [15:1]
            mov     word ptr prdBuf+6, 8000h      ; EOT=1
            ; 物理区域描述符的地址写入PRDTR
            mov     eax, prdBufAddr
            mov     dx, bmcra+BMPRD_REG
            out     dx, eax
            ; 主控命令寄存器的R/W=1, 表示写入内存(读取硬盘)
            outx    bmcra+BMCMD_REG, 08h
            ; 等待硬盘BSY=0和DRQ=0
            call    waitDeviceReady
            ; 设置设备/磁头寄存器的DEV=0
            outx    piobasea1+6, 00h
            ; 等待硬盘BSY=0和DRQ=0
            call    waitDeviceReady
            ; 设备控制寄存器的nIEN=0, 允许中断
            outx    piobaseA2+6, 00
            ; 设置ATA寄存器
            outx    piobasea1+1, 00h              ; =00
            outx    piobaseA1+2, numSect          ; 扇区号
            outx    piobasea1+3, lbaSector >> 0   ; LBA第7~0位
            outx    piobasea1+4, lbaSector >> 8   ; LBA第15~8位
            outx    piobasea1+5, lbaSector >> 16  ; LBA第23~16位
            ; 设备/磁头寄存器:LBA=1, DEV=0, LBA第27~24位
            outx    piobasea1+6, 01000000b or (lbaSector >> 24)  
            ; 设置ATA命令寄存器
            outx    piobasea1+7, 0C8h             ; 0C8h=Read DMA
            ; 读取主控命令寄存器和主控状态寄存器
            inx     bmcra + BMCMD_REG
            inx     bmcra + BMSTA_REG
            ; 主控命令寄存器的R/W=1,Start/Stop=1, 启动DMA传输
            outx    bmcra+BMCMD_REG, 09h
            ; 现在开始DMA数据传送
            ; 检查主控状态寄存器, Interrupt=1时,传送结束
            mov     ecx, 4000h
notAsserted:
            inx     bmcrA+BMSTA_REG
            and     al, 00000100b
            jz      notAsserted
            ; 清除主控状态寄存器的Interrupt位
            outx    bmcra+BMSTA_REG, 00000100b
            ; 读取主控状态寄存器
            inx     bmcra+BMSTA_REG
            ; 主控命令寄存器的Start/Stop=０, 结束DMA传输
            outx    bmcra+BMCMD_REG, 00h
            ret
ReadSectors endp          
;字符显示宏指令的定义
ShowBuffer  PROC
            lea     si,_Buffer     ; 显示_Buffer内容
            cld
            mov     bp,_BufferLen/16
NextLine:   mov     cx,16
NextCh:     lodsb
            push    ax
            shr     al,4
            call    ToASCII
            EchoCh  al
            pop     ax
            call    ToASCII
            EchoCh  al
            EchoCh  ' '
            loop    NextCh
            EchoCh  0dh
            EchoCh  0ah
            dec     bp
            jnz     NextLine
            ret
ShowBuffer  ENDP            
ToASCII     PROC
            and     al,0fh
            cmp     al,10
            jae     Over10
            add     al,'0'
            ret
Over10:     add     al,'A'-10
            ret
ToASCII     ENDP
CSEG        ENDS                           ; 代码段结束
            END     _start


