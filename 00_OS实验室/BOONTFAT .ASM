;        .486P           
        ORG     0C000H 
;CODE    SEGMENT PARA 'CODE' USE16
;        ASSUME  CS:CODE
[BITS   16]
[SECTION .TEXT]        
_START:
        JMP     SHORT START
        NOP
        DB      "Dirichet"      
;-------------------------------------------------
        DW      512             
        DB      8               
        DW      584             
        DB      2               
        DW      0               
        DW      0               
        DB      0f8h            
        DW      0               
        DW      63              
        DW      255             
        DD      63              
        DD      4194241         
;--------------------------------------------------
        DD      3804            
        DW      0               
        DW      0               
        DD      2               
        DW      1               
        DW      6               
        DB      12 DUP(0)       
;-------------------------------------------------
        DB      80H             
        DB      0               
        DB      29H             
        DD      15329558        
        DB      "Dirichlet09"   
        DB      "FAT32   "      

;---------------------------------------------------    
START:
        
        MOV     AX,CS
        MOV     DS,AX
        MOV     ES,AX
        MOV     SS,AX
        MOV     FS,AX 
        MOV     SP,0C000H
;------------------------------------------------
;        MOV     AX,0600H
;        MOV     BX,0700H
;        MOV     CX,0
;        MOV     DX,184FH
;        INT     10H
;------------------------------------------------
        MOV     AX, 0B800H
        MOV     GS,AX
        MOV     BYTE  [GS:0A0H],'B'
        MOV     BYTE  [GS:0A1H],09H
        MOV     BYTE  [GS:0A2H],'O'
        MOV     BYTE  [GS:0A3H],0CH        
        MOV     BYTE  [GS:0A4H],'O'
        MOV     BYTE  [GS:0A5H],0CH   
        MOV     BYTE  [GS:0A6H],'T'
        MOV     BYTE  [GS:0A7H],0CH
;------------------------------------------------
        MOV     EAX,00000042H
        MOV     BX, 0C200H
        MOV     CX, 2
        CALL    RD_DISK_M_16
        MOV     BYTE  [GS:0A8H],'S'
        MOV     BYTE  [GS:0A9H],09H
        jmp     near  loader+2H        
        
        ;DB      0E9H
        ;DW      0FFEFH-48H
;------------------------------------------------
RD_DISK_M_16:      
        MOV     ESI,EAX         
        MOV     DI,CX           
        MOV     DX,1F2H
        MOV     AL,CL
        OUT     DX,AL          
        MOV     EAX,ESI         
        MOV     DX,1F3H                       
        OUT     DX,AL                        
        MOV     CL,8
        SHR     EAX,CL
        MOV     DX,1F4H
        OUT     DX,AL
        SHR     EAX,CL
        MOV     DX,1F5H
        OUT     DX,AL
        SHR     EAX,CL
        AND     AL,0FH          
        OR      AL,0E0H
        MOV     DX,1F6H
        OUT     DX,AL 
        MOV     DX,1F7H
        MOV     AL,20H                        
        OUT     DX,AL  
.NOT_READY:
        NOP
        IN      AL,DX
        AND     AL,88H
        CMP     AL,08H
        JNZ     SHORT .NOT_READY     
        MOV     AX, DI
        MOV     DX, 256
        MUL     DX
        MOV     CX, AX           
        MOV     DX, 1F0H
.GO_ON_READ:
        IN      AX,DX
        MOV     [BX],AX
        ADD     BX,2            
        LOOP    .GO_ON_READ
        RET
;------------------------------------------------
       ; DB      116+178-38-12 DUP(0)
TIMES   510-($-$$) DB 0	   
	   
LOADER:
;-------------------------------------------------
        DW      0AA55H
;CODE    ENDS
;        END     _START


