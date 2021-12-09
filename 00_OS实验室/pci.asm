;------------------------------------------------
 ;功能: 读取PCI 配置信息，存入文件zpci_config.txt
 ;环境: DOS + MASM5
 ;时间: 2021/07
 ;说明: 通过端口CF8h / CFCh 来读取
 ;
 ;---------------------自定义宏结构-------------------
 ;功能: 在文件中换行
 nextrow macro
     mov buffer  ,0dh
     mov buffer+,0ah
     mov dx,offset buffer
     mov cx,
     mov ah,40h
     int 21h
     endm
 ;功能:把ascii 表示的字符写入文件
 tofile macro ascii
     mov buffer,ascii
     mov dx,offset buffer
     mov cx,
     mov ah,40h
     int 21h
     endm
 ;------------------------------------------------
     .386P
 ;-------------------------------------------------
 dseg segment use16
     busnum dw 0000h  ;总线号0 - 00FFh
     devnum dw 001fh  ;设备号0 - 001Fh
     funnum dw 0007h  ;功能号0 - 0007h
     regnum dw 00ffh  ;寄存器0 - 00FFh
     ;
     config_addr dd 00000000h      ;用来暂存eax中的地址
     buff_num db 'bus:device:function:'
     ;
     config_data dd 00000000h      ;用来存放eax中的pci数据
     fname db '\zpci_config.txt', ;文件名
     buffer db
 dseg ends
 ;----------------------------------------------------
 ;----------------------------------------------------
 cseg segment use16
 assume cs:cseg, ds:dseg
 start:
     mov ax,dseg
     mov ds,ax
     ;
     mov dx,offset fname
     mov cx,      ;common file
     mov ah,3ch    ;creat file
     int 21h
     ;
     mov bx,ax     ;save file handle
     ;
     mov busnum,0000h
     mov devnum,0000h
     mov funnum,0000h
     mov regnum,0000h
 ;-----------------------------------------
     call print_num    ;打印busnum:devnum:funnum = 00:00:00
     nextrow           ;换行
 nextreg:
     call pci_read     ;读取pci 配置空间
     cmp regnum,00h
     jnz  continue     ;判断不是第一个寄存器
     cmp ax,0ffffh     ;判断设备是否存在
     jz nextfun        ;不存在，跳到下一个fun
 continue:
     call writefile
     add regnum,      ;只能每次读4个寄存器
     cmp regnum,00ffh  ;判断
     ja nextfun        ;256B 已读完，跳到下一个function
     jmp nextreg       ;否则，读下一个reg
 nextfun:
     nextrow
     ;
     mov regnum,0000h
     inc funnum
     cmp funnum,0007h
     ja nextdev        ;funnum 大于 7,跳到下一个dev
     call print_num
     nextrow
     jmp nextreg
 nextdev:
     mov regnum,0000h
     mov funnum,0000h
     inc devnum
     cmp devnum,001fh
     ja nextbus      ;devnum 大于 1fh，跳到下一个bus
     call print_num
     nextrow
     jmp nextreg
 nextbus:
     mov regnum,0000h
     mov funnum,0000h
     mov devnum,0000h
     inc busnum
     cmp busnum,0005h
     ja endd           ;busnum 大于5，跳到结束
     call print_num
     nextrow
     jmp nextreg
 ;-----------------------结束------------------------
 endd:
     mov ah,3eh   ;close file
     int 21h
     ;
     mov ah,4ch   ;return DOS
     int 21h
 ;---------------------------------------------------
 ;--------------------------------------------------
 ;函数功能:打印busnum:devnum:funnum
 print_num proc
     mov config_addr,eax   ;保护eax中的地址
     ;------------------------------------
     mov dx,offset buff_num
     mov cx,
     mov ah,40h
     int 21h
     ;----------busnum------------
     mov ax,busnum
     push ax
     shr al,
     call toascii
     tofile al
     pop ax
     call toascii
     tofile al
     tofile 2Dh
     ;----------devnum----------
     mov ax,devnum
     push ax
     shr al,
     call toascii
     tofile al
     pop ax
     call toascii
     tofile al
     tofile 2Dh
     ;-----------funnum---------
     mov ax,funnum
     push ax
     shr al,
     call toascii
     tofile al
     pop ax
     call toascii
     tofile al
     ;-----------
     mov eax,config_addr    ;恢复eax
     ret
 print_num endp
 ;------------------------------------------------------
 ;---------------------- writefile ----------------------------
 ;函数功能: 把eax 中的值写入文件
 ;入口参数: eax
 ;出口参数: 无
 ;所用寄存器和存储单元:ebx,ecx,edx
 writefile proc
     mov config_data,eax   ;用config_data暂存eax中的pci数据
     ;--------第一个字节-----
     push eax
     shr al,
     call toascii
     tofile al
     pop eax
     call toascii
     tofile al
     tofile 20h
     ;--------第二个字节------
     mov eax,config_data
     shr eax,
     ;
     push eax
     shr al,
     call toascii
     tofile al
     pop eax
     call toascii
     tofile al
     tofile 20h
     ;--------第三个字节-------
     mov eax,config_data
     shr eax,
     ;
     push eax
     shr al,
     call toascii
     tofile al
     pop eax
     call toascii
     tofile al
     tofile 20h
     ;--------第四个字节---------
     mov eax,config_data
     shr eax,
     ;
     push eax
     shr al,
     call toascii
     tofile al
     pop eax
     call toascii
     tofile al
     tofile 20h
     ret
 writefile endp
 ;---------------------------------------------------
 ;-----------------------toascii---------------------------
 ;子程序名: toascii
 ;功能: 把al的低4位的值转成ascii码，存入al
 ;入口参数: al
 ;出口参数: al
 toascii proc
     and al,0fh
     add al,90h
     daa
     adc al,40h
     daa
     ret
 toascii endp
 ;----------------------------------------------------
 ;----------------------pci_read---------------------------
 ;子程序名: pci_read
 ;功能: 根据eax中的地址读取pci的配置空间,并存入eax
 ;入口参数: busnum、devnum、funnum、regnum
 ;出口参数: eax
 ;
 pci_read proc
     ;protect register
     push ebx
     push dx
     ;clear
     xor eax,eax
     xor ebx,ebx
     ;enable
     add eax,1h
     shl eax,
     ;bus number
     mov ebx,ds:[]
     and ebx,0ffh
     shl ebx,
     add eax,ebx
     ;device number
     xor ebx,ebx
     mov ebx,ds:[]
     and ebx,0ffh
     shl ebx,
     add eax,ebx
     ;function number
     xor ebx,ebx
     mov ebx,ds:[]
     and ebx,0ffh
     shl ebx,
     add eax,ebx
     ;register
     xor ebx,ebx
     mov ebx,ds:[]
     and ebx,0ffh
     add eax,ebx
     ;read IO
     mov dx,0cf8h
     out dx,eax
     mov dx,0cfch
     in eax,dx
     ;resume register
     pop dx
     pop ebx
     ret
 pci_read endp
 ;--------------------------------------------
 ;----------------------------------------------
 cseg ends
     end start