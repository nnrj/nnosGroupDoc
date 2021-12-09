;/*
;*****************************************************************************************************
;*                                          Sun-system                                               *
;*                                     The Real-Time Kernel                                          *
;*                                        system include                                             *
;*                           (c) Copyright 2020.01-2020.12, yls, yichang                             *
;*                                      All Rights Reserved                                          *
;* File : boot.asm                        WriteBy   : Yls                                            *
;*****************************************************************************************************
;*/
;/* ----------------------------------------------------------------------------------------------- */
;/* 说明：boot.c就是一个加载内核初始代码的工具，写入引导区的；加上其他数据，大小要小于512字节。     */
;/*       这个文件也可以用汇编写好，编译后用专门的工具写入引导区。                                  */
;/*       此处可能采用直接以db命令定义的二进制指令的方式，这样可以直接拷贝现有硬盘的引导区。        */
;/* 注  ：这个文件写入MBR。                                                                         */
;/* LBA : 逻辑地址是按“簇”运算的，而绝对地址是按磁头,柱面,扇区定位的。最小单位是扇区，一般          */
;/*       1簇 = N个扇区（一般为512字节）                                                            */
;/*       它们的关系N是根据具体操作系统而定的，你可以在引导区中查到这个参数Sectors_per_cluster。    */
;/* ----------------------------------------------------------------------------------------------- */
;/* 说明：X86端口地址是16位，端口位数是8位，数据端口是16位                                          */
;/*       采用48位PIO方式低版本芯片组容易不支持，需要查看虚拟机芯片组                               */
;/*       48-bit LBA方式:  (5-4-3，5-4-3,这样不知道是否可行)                                        */
;/*          0x1F0：数据端口                                                                        */
;/* 写两次   0x1f1端口: 0                                                                           */
;/* 写两次   0x1f2端口: 第一次要读的扇区数的高8位,第二次低8位                                       */
;/* 写       0x1f3: LBA参数的24~31位                                                                */
;/* 写       0x1f3: LBA参数的0~7位                                                                  */
;/* 写       0x1f4: LBA参数的32~39位                                                                */
;/* 写       0x1f4: LBA参数的8~15位                                                                 */
;/* 写       0x1f5: LBA参数的40~47位                                                                */
;/* 写       0x1f5: LBA参数的16~23位                                                                */
;/* 写       0x1f6: 7~5位,010,第4位0表示主盘,1表示从盘,3~0位,0  =51 01010000 第六位的1表示LBA寻址   */
;/* 写       0x1f7: 0x24为读, 0x34为写                                                              */
;-----------------------------------------------------------------------------------------------------
;/*   0x1f0 ;1个16位的端口，连续取出数据                                                            */
;/*   0x1f1 ;错误寄存器，包含硬盘驱动器最后一次执行命令后的状态(错误原因）                          */
;/*   0x1f2 ;读取的扇区数量                                                                         */
;/*   0x1f3 ;逻辑地址的0~7位                                                                        */
;/*   0x1f4 ;逻辑地址的8~15位                                                                       */
;/*   0x1f5 ;逻辑地址的16~23位                                                                      */
;/*   0x1f6 ;28位：高3位是010,表LAB模式，第5位硬盘号，0主盘，1从盘，低4位存放逻辑地址的24~27位。    */
;/*          48位：高3位是010,表LAB模式，第5位硬盘号，0主盘，1从盘                                  */
;/*         7     6     5     4     3     2     1     0                                             */
;/*        obs   LBA   obs   DEV   rev   rev   rev   rev                                            */
;/*             1:LBA       0主1从 --------保留---------      LBA28位是24-27位地址                  */
;/*                  *************0x1F6=040H**************一般自己写用40H                           */
;/*   0x1f7 ;命令端口同时也是状态端口，0x20表示读扇区(48位为24)，当为状态端口时，各位代表意思如下图	*/
;/*	         28位lba  读扇区是20h命令字  见卷1  234页  写扇区命令字30h  见卷1  367页                */
;/*	         48位lba  读扇区是24h命令字  见卷1  237页  写扇区命令字34h  见卷1  369页                */
;--------------------------------------------------------------------------------------------------
;/*   01f7既是命令寄存器，也是状态寄存器，（状态值，28位与48位相同）                                */
;/*   7    6     5      4     3    2     1     0                                                    */
;/*  obs  LBA   obs    DEV   res  res   res   res   -----命令状态  读命令字：24H  写命令字：34H     */
;/*  BSY  DRDY               DRQ              ERR   -----状态状态                                   */
;/*  BSY  DRDY   DF     空   DRQ   空    空   ERR   -----状态状态                                   */
;/*  BSY  程序开始测试此位，以查看硬盘是否忙。                                                      */
;/*  DRDY 硬盘就绪。                                       7、8两位，一般测设第8位。                */
;/*  DF   清0，这位基本不管。                                                                       */
;/*  DRQ  数据块准备就绪，会被置1，读写命令发出后，都要测试该位是否为1，若为1进行下步操作。         */
;/*  ERR  此位为1表示有错误发生，错误码放在1F1寄存器中。                                            */
;/* ----------------------------------------------------------------------------------------------- */
                      bits 16
;-----------------------------------------------------------------------------------------------------
;定义BPB数据结构                           ;                    /* 定义bios识别磁盘的BPB数据结构    */
                      ORG  7c00h           ;        offset: 00H /* 定义加载到内存0：7c00的位置      */
                      JMP  START           ; 02字节 offset: 00H /* 跳转指令03个字节                 */
                      NOP                  ; 01字节 offset: 02H
OEM                   DB   "Dirichet"      ; 08字节 offset: 04H /* 厂商标志字节               8     */
; ------------------------------------------------------------- /* ------BIOS基本BPB结构定义 ------ */
Bytes_per_sector      DW   512             ; 02字节 offset: 0BH /* BPB，扇区字节数            512   */
Sectors_per_cluster   DB   8               ; 01字节 offset: 0DH /* BPB，每族扇区数            8     */
Reserved_sectors      DW   584             ; 02字节 offset: 0EH /* BPB，fat表前所有保留的扇区数     */
Number_of_FATs        DB   2               ; 01字节 offset: 10H /* BPB，FAT表数               2     */
Root_entries          DW   0               ; 02字节 offset: 11H /* BPB，根目录  FAT32必须为0  0     */
Sectors_small         DW   0               ; 02字节 offset: 13H /* BPB，小扇区  不再使用      0     */
Media_descriptor      DB   0f8h            ; 01字节 offset: 15H /* BPB，介质描述     F8：硬盘 0f8h  */
Sectors_per_FAT_small DW   0               ; 02字节 offset: 16H /* BPB，fat32未使用           0     */
Sectors_per_track     DW   63              ; 02字节 offset: 18H /* BPB，每道逻辑扇区数        63    */
Heads                 DW   255             ; 02字节 offset: 1AH /* BPB，逻辑磁头数            255   */
Hidden_sectors        DD   63              ; 04字节 offset: 1CH /* BPB，本分区前已用扇区数 8-11字节 */
Sectors               DD   3902913         ; 04字节 offset: 20H /* BPB，总的扇区数12-11字节   2G    */
; ------------------------------------------------------------- /* ---------BPB之FAT32参数--------- */
Sectors_per_FAT       DD   3804            ; 04字节 offset: 24H /* BPB，每fat扇区数           3804  */
Extended_flags        DW   0               ; 02字节 offset: 28H /* BPB，FAT备份标志           0     */
Version               DW   0               ; 02字节 offset: 2AH /* BPB，版本                  0     */
Root_dir_1st_cluster  DD   2               ; 04字节 offset: 2CH /* BPB，根目录开始族号        2     */
FSInfo_sector         DW   1               ; 02字节 offset: 30H /* BPB，DBR占用的扇区数       1     */
Backup_boot_sector    DW   6               ; 02字节 offset: 32H /* BPB，备份DBR地址           6     */
             times 12 DB   0               ; 12字节 offset: 34H /* BPB，保留12未使用字节      12    */
; ------------------------------------------------------------- /* --------其它BPB 26个字节-------- */
BIOS_drive            DB   80              ; 01字节 offset: 40H /* BPB，bios硬盘识别代码      80    */
                      DB   0               ; 01字节 offset: 41H /* BPB，用于int13呼叫         80    */
Ext_boot_signature    DB   29              ; 01字节 offset: 42H /* BPB，扩展引导标志          29    */
Volume_serial_number  DD   15329558        ; 04字节 offset: 43H /* BPB，随机产生的序列号            */
Volume_label          DB   "Dirichlet09"   ; 11字节 offset: 47H /* BPB，人工输入卷标号              */
File_system           DB   "FAT32"         ; 08字节 offset: 52H /* BPB，文件系统标识号              */
; ------------------------------------------------------------- /* ----------扩展BPB 26 字节------- */

; /* ---------------------------------以下是启动代码88-446字节------------------------------------- */
START:         XOR  AX,AX                                ;  /* 主程序的寄存器清0                    */
               MOV  BX,AX                                ;
               MOV  CX,AX                                ;
               MOV  DX,AX                                ;
			   MOV  SI,AX                                ;
			   MOV  DI,AX                                ;
			   MOV  BP,AX                                ;
			   MOV  SP,7C00H                             ;  /* 堆栈先这样吧                         */
			   MOV  DS,AX                                ;
			   MOV  ES,AX                                ;
			   MOV  SS,AX                                ;
			   MOV  FS,AX                                ;
			   MOV  GS,AX                                ;
			   ;置要读写的扇区地址H16：M16：L16
			   
    		   CALL CHECKREADY                           ;  /* 检查硬盘忙否？                       */
			   CALL READSECTER                           ;  /* 读写磁盘                             */
			   JMP  $;
               
READSECTER:    XOR  AX,AX                                ;  ---------错位与参数1F1---------
			   MOV  DX,01F1h;                            ;  /* IF1第一次写0                         */
			   OUT  DX,AL;
			   NOP                                       ;  /* 延时三条指令周期                     */
			   NOP                                       ;
   			   XOR  AX,AX                                ;  ---------错位与参数1F1---------
			   MOV  DX,01F1h;                            ;  /* IF1第二次写0                         */
			   OUT  DX,AL;			   
			   NOP                                       ;  /* 延时三条指令周期                     */
			   NOP                                       ;
               ;---------设置读取扇区数----------
			   MOV  DX,01f2h;                            ;  /* IF2写扇区高8位                       */
			   MOV  AX,Secter                            ;  /* 要读写的扇区数读入ax寄存器           */
			   SHR  AX,8;                                ;  /* 高八位移到AL                         */
			   OUT  DX,AL;
			   NOP                                       ;  /* 延时三条指令周期                     */
			   NOP                                       ;
			   MOV  DX,01f2h;                            ;  /* IF2写扇区低8位                       */
			   MOV  AX,Secter                            ;  /* 要读写的扇区数读入ax寄存器           */
			   OUT  DX,AL;
			   NOP                                       ;  /* 延时三条指令周期                     */
			   NOP                                       ;
			   ;---------设置读取扇区数----------
			   ;  48位扇区地址格式：LBA
			   ;先写高24位，1f5-1f4-1f3：24-31：32-39：40-47再写低24位：1f5-1f4-1f3：0-7：8-15：16-23
			   MOV  AX,[LBA+02]                          ;  /* 写IF5端口LBA地址24-31位              */
			   MOV  DX,01F3h;
			   OUT  DX,AL;
			   NOP        ;
			   NOP        ;
			   MOV  AX,[LBA+05]                          ;  /* 写IF4端口LBA地址0-7位                */
			   MOV  DX,01F3h;
			   OUT  DX,AL;
  			   NOP        ;
			   NOP        ;

			   MOV  AX,[LBA+01]                          ;  /* 写IF3端口LBA地址32-39位              */
			   MOV  DX,01F4h;
			   OUT  DX,AL;
			   NOP        ;
			   NOP        ;
			   MOV  AX,[LBA+04]                          ;  /* 写IF5端口LBA地址8-15位               */
			   MOV  DX,01F4h;
			   OUT  DX,AL;
			   NOP        ;
			   NOP        ;

			   MOV  AX,[LBA+00]                          ;  /* 写IF4端口LBA地址47-40位              */
			   MOV  DX,01F5h;
			   OUT  DX,AL;
			   NOP        ;
			   NOP        ;
			   MOV  AX,[LBA+03]                          ;  /* 写IF3端口LBA地址23-16位              */
			   MOV  DX,01F5h;
			   OUT  DX,AL;
			   NOP        ;
			   NOP        ;
               ;---------设置lba方式及设备号--------
			   MOV  DX,01F6h                             ;
			   MOV  AL,040h           ;主盘40H           ;  /* IF6参数7:LBA/1-4:0/5:主0从1          */
			   OUT  DX,AL;
			   NOP        ;
			   NOP        ;
		       ;--------------发读命令--------------
               MOV  DX,01F7h;
			   MOV  AL,024h                              ;  /* IF7=24 读；IF7=34 写；               */
               OUT  DX,AL;
			   NOP       ;
			   NOP       ;			   
			   ;---------查看1F7命令端口状态--------
STATE:  	   MOV  DX,01F7H                             ;
               IN   AL,DX;
      	       TEST AL,08H                               ;  /* 此处查询数据块是否就绪的DRQ位        */
			   JZ  STATE                                 ;  /* 如果忙就等到完成，才可以读写数据     */
			   
               MOV  CX,256                               ;  /* 设置循环次数                         */
			   MOV  BX,05c00h                            ;  /* 设置数据存放目的地址  00：5c00       */
			   MOV  DX,1F0h                              ;  /* 设置数据端口地址                     */
RAED:		   IN   AX,DX;                               ;  /* 注意：读入的是字，一次读入两个字节   */
			   MOV  [BX],AX;
			   ADD  BX,2                                 ;  /* 目的地址修正                         */
			   LOOP RAED                                 ; 
			   
			   MOV  AX,05C00H                            ;  /* 显示读的第二扇区的内容               */
			   MOV  DX,0102H                             ;  /* 设置显示位置     0202                */
			   MOV  [MSGBUF],AX                          ;
			   MOV  DX,0503H                               ;
			   CALL DISPLAY                              ;     显示 代码段 需要转换
			   
			   MOV  AX,BOOTMESSAGE                       ;     显示注释
			   MOV  [MSGBUF],AX                          ;
			   MOV  DX,0203H                             ;  /* 设置显示位置     0204                */
			   CALL DISPLAY                              ;
			   JMP  $                                    ;
			   
DISPLAY:       MOV  AX,[MSGBUF]                          ;  /* 显示地址ES:BP=字符首址               */
			   MOV  BP,AX;
			   MOV  CX,60                                ;  /* 设置要显示的字符个数                 */
               ; MOV  DH,0                               ;  /* 设置显示行                           */
               ; MOV  DL,0                               ;  /* 设置显示列                           */
			   MOV  AX,01301H                            ;  /* AH=13H, AL=01H                       */
			   MOV  BX,00CH                              ;  /* 页号BH=00H, 黑底红字AL=0CH，1F白字   */
			   INT  10H                                  ;  /* 10号中断                             */
			   RET                                       ;
			   
CHECKREADY:    MOV  DX,01F7H                             ;  /* 这段代码检测7位，以测硬盘是否空闲    */
               IN   AL,DX                                ;
               TEST AL,040H                              ;
               JZ   CHECKREADY                           ;
               RET                                       ;
			   
;CHECKCOMPLETE: MOV  DX,01F7H                             ;  直接写在里面了，不用这个子程序了。
;               IN   AL,DX                                ;
;               TEST AL,08H                               ;
;               JZ   CHECKCOMPLETE                        ;
;               RET                                       ;			   

MSGBUF:        DB   00, 00        			             ;  /* 显示地址                             */
LBA:           DB   00, 00, 00, 00, 00, 01               ;	/* 设置要读取的LBA扇区，LBA从0开始      */	
Secter         EQU  001                                  ;  /* 扇区数	                            */
OK:            DB   "secter read ok!"
BOOTMESSAGE:   DB   "Read secter data OK! the next test call C. "
			   
               TIMES 510-($-$$) DB 0			         ;
               DW  0x0aa55                               ;








			   
			   
			   
			   