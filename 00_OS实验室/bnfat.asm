;        .486P
        ORG     7C00H 
;CODE    SEGMENT PARA 'CODE' USE16
;        ASSUME  CS:CODE
[BITS 16]
[SECTION .TEXT]
_START:
        MOV     AX,CS
        MOV     DS,AX
        MOV     ES,AX
        MOV     SS,AX
        MOV     FS,AX 
        MOV     SP,7C00H
;--------------------------------------------------
        MOV     AX,0600H
        MOV     BX,0700H
        MOV     CX,0
        MOV     DX,184FH
        INT     10H
;-------------------------------------------------
        MOV     AX, 0B800H
        MOV     GS,AX
        MOV     BYTE  [GS:00H],'M'
        MOV     BYTE  [GS:01H],0CH
        MOV     BYTE  [GS:02H],'B'
        MOV     BYTE  [GS:03H],0CH
        MOV     BYTE  [GS:04H],'R'
        MOV     BYTE  [GS:05H],0CH
;------------------------------------------------
        MOV     EAX,0000003fH
        MOV     BX, 0C000h
        MOV     CX, 2
        CALL    RD_DISK_M_16
        ;JMP     NEAR PTR BOOT-1BEH+300H
        ;JMP     NEAR PTR BOOT-1BEH+4600H-42h
        ;JMP     NEAR PTR BOOT
        JMP      NEAR BOOT
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
        ;DB      103+176 DUP(0)
TIMES 446-($-$$) DB 0
;------------------------------------------------
PART:
        DB      80H
        DB      01H
        DB      01H
        DB      00H
        DB      0BH
        DB      0FEH
        DB      0BFH
        DB      0FCH
        DD      0000003FH
        DD      4194241
;-------------------------------------------------        
        ;DB      48 DUP(0)
TIMES 48 DB     0  
;-------------------------------------------------
        DW      0AA55H
BOOT:
;CODE    ENDS
;        END     _START


