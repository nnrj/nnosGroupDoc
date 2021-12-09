;            .486P
[MAP SYMBOLS JMPNB.MAP]
            ORG         0C200H
;CODE        SEGMENT     PARA 'CODE' USE16
;            ASSUME      CS:CODE
[BITS 16]
[SECTION .TEXT]
_START:
            JMP         SHORT BEGIN
            nop
;-------------------------------------------------
GDT:
            DD          00000000H,00000000H
            DD          0000FFFFH,00CF9200H
            DD          0000FFFFH,00CF9A00H
            DD          80000007H,00CF920BH
            DD          00000010H,00CF920AH
;-------------------------------------------------
GDT_PTR:
            DW          $-GDT-1
            DD          GDT
;-------------------------------------------------
LFBBASE     EQU         00090000H
VBEMODE     EQU         0105H                       ; 1024 X  768 X 8BIT 彩色
CYLS        EQU         0FF0H                       ; 引导扇区设置
LEDS        EQU         0FF1H
VMODE       EQU         0FF2H                       ; 关于颜色的信息
SCRNX       EQU         0FF4H                       ; 分辨率X
SCRNY       EQU         0FF6H                       ; 分辨率Y
VRAM        EQU         0FF8H
;-------------------------------------------------
BEGIN:             
            XOR         AX,AX
            MOV         AX,CS             
            MOV         DS,AX
            MOV         SS,AX
            MOV         SP,0C200H
;-------------------------------------------------
            MOV         AX,09000H
            MOV         ES,AX
            MOV         DI,0
            MOV         AX,4F00H
            INT         10H
;------------------------------------------------
            CMP         AX,004FH
            JNE         SCRN640
            MOV         AX,[ES:DI+4]
            CMP         AX,0200H
            JB          SCRN640
            MOV         CX,VBEMODE
            MOV         AX,4F01H
            INT         10H
;------------------------------------------------
            CMP         AX,004FH
            JNE         SCRN640
            CMP         BYTE [ES:DI+19H],8
            JNE         SCRN640
            CMP         BYTE [ES:DI+1BH],4              
            JNE         SCRN640
            MOV         AX,[ES:DI+00H]                              
            AND         AX,0080H
            JZ          SCRN640                             
            MOV         BX,VBEMODE+4000H
            MOV         AX,4F02H
            INT         10H
;-------------------------------------------------
            MOV         BYTE [DS:VMODE],8  
            MOV         AX,[ES:DI+12H]
            MOV         [DS:SCRNX],AX
            MOV         AX,[ES:DI+14H]
            MOV         [DS:SCRNY],AX
            MOV         EAX,[ES:DI+28H] 
            MOV         [DS:VRAM],EAX
            JMP         SHORT PROMODE
;-------------------------------------------------
SCRN640:
            MOV         AL,13H                                         
            MOV         AH,00H
            INT         10H
            MOV         BYTE [DS:VMODE],8        
            MOV         WORD [DS:SCRNX],320
            MOV         WORD [DS:SCRNY],200
            MOV         DWORD [DS:VRAM],000A0000H
;----------------------------------------------------
PROMODE:
            IN          AL,92H
            OR          AL,00000010B
            OUT         92H,AL
            CLI             
            MOV         EAX,CR0
            OR          EAX,1
            MOV         CR0,EAX
            LGDT        [GDT_PTR]
            ;DB          66H
            ;DB          0EAH
            ;DD          OFFSET FLUSH+0C2F0H
            ;DW          0010H
            JMP        DWORD 0010h:FLUSH
;CODE        ENDS
;---------------------------------------------------
;CSEG        SEGMENT     PARA 'CODE32' USE32
;            ASSUME      CS:CSEG
[BITS 32]
[SECTION .CSEG]
FLUSH:
            MOV         AX,0008H
            MOV         DS,AX
            MOV         ES,AX
            MOV         SS,AX
            MOV         AX,0018H
            MOV         FS,AX
            MOV         AX,0020H
            MOV         GS,AX
;---------------------------------------------------
;            PUSH        ES
;            PUSH        DS
;            PUSHAD
;            MOV         EAX,DS:[VRAM]
;            MOV         DS:[LFBBASE],EAX
;            MOV         EDI,DWORD PTR DS:[LFBBASE]
;            MOV         EDX,0             
;            MOV         CX,DS:[SCRNX];1024
;LX:         PUSH        CX
;            MOV         CX,DS:[SCRNY];768
;LY:         MOV         BYTE PTR DS:[EDI+EDX*1],3
;            INC         EDX
;            LOOP        LY
;            POP         CX
;            LOOP        LX
;            POPAD
;            POP         DS
;            POP         ES
;---------------------------------------------------
;            PUSH        EDX
;            PUSH        ECX
;            PUSH        EAX
;            PUSH        EBX
;            XOR         ECX,ECX            
;UL_LR:      
;            XOR         EAX,EAX
;            XOR         EBX,EBX
;            XOR         EDX,EDX    
;            ADD         BX,CX
;            MOV         AX,1
;            MUL         CX
;            MOV         BX,AX
;            SHL         DX,1
;            ADD         AX,DX
;            MOV         BX,AX
;            MOVZX       EBX,BX            
;            MOV         BYTE PTR GS:[ECX],3
;            INC         ECX
;            CMP         ECX,65535
;            JB          UL_LR             
;            POP         EBX
;            POP         EAX
;            POP         ECX
;            POP         EDX
;---------------------------------------------------             
            MOV         EAX,00000009H
            MOV         EBX,00280000H
            MOV         ECX,200
            CALL        RD_DISK_M_32 
;---------------------------------------------------
            MOV         EAX,0H
            MOV         EBX,00100000H
            MOV         ECX,1
            CALL        RD_DISK_M_32
;---------------------------------------------------
            ;MOV         EAX,00000002H
            MOV         EAX,00000042H
            MOV         EDI,00100000H+512
            MOV         EBX,EDI
            MOV         ECX,4
            CALL        RD_DISK_M_32
;---------------------------------------------------                    
KERNEL_INIT:                   
            MOV         EBX,00280000H
            MOV         ECX,[EBX+16]
            ADD         ECX,3                   
            SHR         ECX,2                   
            JZ          SHORT SKIP                    
            MOV         ESI,[EBX+20]    
            ADD         ESI,EBX
            MOV         EDI,[EBX+12]    
            CALL        MEMCPY
SKIP:
            MOV         ESP,[EBX+12]
            ;DB          0E9H
            ;DD          00270188H 
            DB          0EAH
            DD          00250000h
            DW          0010H
;---------------------------------------------------
RD_DISK_M_32:   
            MOV         ESI,EAX           
            MOV         DI,CX             
            MOV         DX,1F2H
            MOV         AL,CL
            OUT         DX,AL            
            MOV         EAX,ESI           
            MOV         DX,1F3H                       
            OUT         DX,AL                       
            MOV         CL,8
            SHR         EAX,CL
            MOV         DX,1F4H
            OUT         DX,AL
            SHR         EAX,CL
            MOV         DX,1F5H
            OUT         DX,AL
            SHR         EAX,CL
            AND         AL,0FH           
            OR          AL,0E0H           
            MOV         DX,1F6H
            OUT         DX,AL
            MOV         DX,1F7H
            MOV         AL,20H                        
            OUT         DX,AL
.NOT_READY:                
            NOP
            IN          AL,DX
            AND         AL,88H           
            CMP         AL,08H
            JNZ         .NOT_READY        
            MOV         AX, DI                              
            MOV         DX, 256           
            MUL         DX
            MOV         CX, AX    
            MOV         DX, 1F0H
.GO_ON_READ:
            IN          AX,DX   
            MOV         [EBX], AX
            ADD         EBX, 2           
            LOOP        .GO_ON_READ
            RET
;----------------------------------------------------
MEMCPY:
            MOV         EAX,[ESI]
            ADD         ESI,4
            MOV         [EDI],EAX
            ADD         EDI,4
            SUB         ECX,1
            JNZ         MEMCPY
            RET

KERNELC:

;CSEG        ENDS
;            END         _START
