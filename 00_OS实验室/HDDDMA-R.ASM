;程序清单: hdddma-r.asm(实模式下的硬盘DMA)
.386P
;bmcr_base_addr  EQU    0C000H       ; DMA主控寄存器首地址
bmcr_base_addr  EQU    18B0H
numSect         EQU    1            ; 读取1个扇区
lbaSector       EQU    0            ; LBA=0
BM_COMMAND_REG  EQU    0            ; 主控命令寄存器的偏移
BM_STATUS_REG   EQU    2            ; 主控状态寄存器的偏移
BM_PRD_ADDR_REG EQU    4            ; 物理区域描述符指针寄存器的偏移
pio_base_addr1  EQU    01F0H        ; ATA设备控制块寄存器基地址
pio_base_addr2  EQU    03F0H        ; ATA命令命令块寄存器基地址
DSEG            SEGMENT USE16       ; 16位数据段
ALIGN 2                       
_Buffer         db      512*numSect dup (0)   ; 内存缓冲区
_BufferLen      equ     $-_Buffer
ALIGN 4                       
prdBuf          dd      0           ; 物理区域描述符
                dd      0
prdBufAddr      dd      0           ; 物理区域描述符地址
bufferaddr      dd      0           ; 内存缓冲区地址
DSEG            ENDS                ; 数据段结束
SSEG            SEGMENT PARA STACK  ; 堆栈段
                DB      512 DUP (0)
SSEG            ENDS                ; 堆栈段结束
outx            MACRO   Reg, Val    ; 向Reg端口写入数据Val
                mov     dx, Reg
                mov     al, Val
                out     dx, al
                ENDM
inx             MACRO   Reg         ; 从Reg端口读入数据, 存放在AL中
                mov     dx, Reg
                in      al, dx
                ENDM           
CSEG            SEGMENT USE16       ; 代码段
                ASSUME  CS:CSEG,DS:DSEG
; 检查ATA状态寄存器, 直到BSY=0和DRQ=0
waitDeviceReady proc
waitReady:
                inx     pio_base_addr1+7    ; 读取ATA状态寄存器
                and     al, 10001000b       ; BSY=1或DRQ=1,继续查询
                jnz     waitReady
                ret
waitDeviceReady endp
; 采用DMA方式读取硬盘扇区
ReadSectors     proc              
                ; Start/Stop=0, 停止以前的DMA传输
                outx    bmcr_base_addr+BM_COMMAND_REG, 00h
                ; 清除主控状态寄存器的Interrupt和Error位
                outx    bmcr_base_addr+BM_STATUS_REG, 00000110b
                ; 建立一个物理区域描述符
                mov     eax, bufferaddr
                mov     prdBuf, eax                   ; Physical Address
                mov     word ptr prdBuf+4, _BufferLen ; Byte Count [15:1]
                mov     word ptr prdBuf+6, 8000h      ; EOT=1
                ; 物理区域描述符的地址写入PRDTR
                mov     eax, prdBufAddr
                mov     dx, bmcr_base_addr+BM_PRD_ADDR_REG
                out     dx, eax
                ; 主控命令寄存器的R/W=1, 表示写入内存(读取硬盘)
                outx    bmcr_base_addr+BM_COMMAND_REG, 08h
                ; 等待硬盘BSY=0和DRQ=0
                call    waitDeviceReady
                ; 设置设备/磁头寄存器的DEV=0
                outx    pio_base_addr1+6, 00h
                ; 等待硬盘BSY=0和DRQ=0
                call    waitDeviceReady
                ; 设备控制寄存器的nIEN=0, 允许中断
                outx    pio_base_addr2+6, 00
                ; 设置ATA寄存器
                outx    pio_base_addr1+1, 00h              ; =00
                outx    pio_base_addr1+2, numSect          ; 扇区号
                outx    pio_base_addr1+3, lbaSector >> 0   ; LBA第7~0位
                outx    pio_base_addr1+4, lbaSector >> 8   ; LBA第15~8位
                outx    pio_base_addr1+5, lbaSector >> 16  ; LBA第23~16位
                ; 设备/磁头寄存器:LBA=1, DEV=0, LBA第27~24位
                outx    pio_base_addr1+6, 01000000b or (lbaSector >> 24)  
                ; 设置ATA命令寄存器
                outx    pio_base_addr1+7, 0C8h             ; 0C8h=Read DMA
                ; 读取主控命令寄存器和主控状态寄存器
                inx     bmcr_base_addr + BM_COMMAND_REG
                inx     bmcr_base_addr + BM_STATUS_REG
                ; 主控命令寄存器的R/W=1,Start/Stop=1, 启动DMA传输
                outx    bmcr_base_addr+BM_COMMAND_REG, 09h
                ; 现在开始DMA数据传送
                ; 检查主控状态寄存器, Interrupt=1时,传送结束
                mov     ecx, 4000h
notAsserted:
                inx     bmcr_base_addr+BM_STATUS_REG
                and     al, 00000100b
                jz      notAsserted
                ; 清除主控状态寄存器的Interrupt位
                outx    bmcr_base_addr+BM_STATUS_REG, 00000100b
                ; 读取主控状态寄存器
                inx     bmcr_base_addr+BM_STATUS_REG
                ; 主控命令寄存器的Start/Stop=０, 结束DMA传输
                outx    bmcr_base_addr+BM_COMMAND_REG, 00h
                ret
ReadSectors     endp          
         
Start           PROC
                mov     ax,DSEG
                mov     ds,ax                   ; ds指向数据段
                mov     es,ax                   ; es指向数据段
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
Start           ENDP
;字符显示宏指令的定义
EchoCh          MACRO   ascii
                mov     ah,2
                mov     dl,ascii
                int     21h
                ENDM        
ShowBuffer      PROC
                lea     si,_Buffer     ; 显示_Buffer内容
                cld
                mov     bp,_BufferLen/16
NextLine:       mov     cx,16
NextCh:         lodsb
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
ShowBuffer      ENDP            
ToASCII         PROC
                and     al,0fh
                cmp     al,10
                jae     Over10
                add     al,'0'
                ret
Over10:
                add     al,'A'-10
                ret
ToASCII         ENDP
CSEG            ENDS                           ; 代码段结束
                END     start
;10.4 实验题：保护方式下的硬盘DMA传输实验
;程序hdddma-r.asm工作在实模式下，未采用中断技术。在该程序的基础上，在保护模式下实现硬盘DMA传输，编写中断处理程序来检测DMA传输是否结束。
;PCI-IDE控制器有2个IDE通道，主通道DMA传输结束后产生中断请求IRQ14，次通道产生中断请求IRQ15。
;IRQ14、IRQ15连接在从片8259上，从片8259连接到主片8259的IRQ2。
;要求：
;1．    将hdddma-r.asm修改为保护模式运行，可结合interpt.asm进行；
;2．    设置从片8259的中断类型号为28H~2FH。IRQ14对应的中断类型号为2EH。在IDT中为该中断设置处理程序；
;3．    设置从片8259的OCW1，第6位必须为0，允许IRQ14。主片8259的OCW1，第2位必须为0，允许IRQ2。
;4．    IRQ14中断处理结束时，必须先后向从片8259、主片8259发送EOI命令。
;5．    将c:/asm/tool/vbox/HDD0.vdi挂接在VirtualBox的第二IDE控制器的从盘，修改程序，使之能够以DMA方式读取硬盘扇区；
;6．    修改程序，使之能够以DMA方式写入硬盘扇区。


