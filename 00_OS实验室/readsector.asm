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