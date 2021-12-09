        
SECTION .TEXT
        ORG     8000H
START:
        JMP     SHORT BEGIN
        NOP
;-----------------------------------------------------------------------------
VBEMODE EQU     105H             
BOTPAK  EQU     00280000H
;-----------------------------------------------------------------------------
CYLS    EQU     0ff0H            
LEDS    EQU     0ff1H
VMODE   EQU     0ff2H            
SCRNX   EQU     0ff4H            
SCRNY   EQU     0ff6H            
VRAM    EQU     0ff8H           
;----------------------------------------------------------------------------        
GDT: 
        DD      00000000H,00000000H                      
        DD      0000FFFFH,00CF9200H 
        DD      0000FFFFH,00CF9A28H   
		
GDTR0:
        DW      $-GDT-1
        DD      GDT 
                 
;-----------------------------------------------------------------------------
BEGIN:
        MOV     AX,9000H
        MOV     ES,AX
        MOV     DI,0
        MOV     AX,4f00H
        INT     10H
        CMP     AX,004fH
        JNE     scrn320
;----------------------------------------------------------------------------
        MOV     AX,[ES:DI+4]
        CMP     AX,0200H
        JB      scrn320          
;----------------------------------------------------------------------------
        MOV     CX,VBEMODE
        MOV     AX,4f01H
        INT     10H
        CMP     AX,004fH
        JNE     scrn320
;----------------------------------------------------------------------------
        CMP     BYTE [ES:DI+19H],8
        JNE     scrn320
        CMP     BYTE [ES:DI+1bH],4
        JNE     scrn320
        MOV     AX,[ES:DI+00H]
        AND     AX,0080H
        JZ      scrn320          
;---------------------------------------------------------------------------
        MOV     BX,VBEMODE+4000H
        MOV     AX,4f02H
        INT     10H
        MOV     BYTE [VMODE],8 
        MOV     AX,[ES:DI+12H]
        MOV     [SCRNX],AX
        MOV     AX,[ES:DI+14H]
        MOV     [SCRNY],AX
        MOV     EAX,[ES:DI+28H]
        MOV     [VRAM],EAX
        JMP     keystatus
;--------------------------------------------------------------------------
scrn320:
        MOV     AL,13H          
        MOV     AH,00H
        INT     10H
        MOV     BYTE [VMODE],8 
        MOV     WORD [SCRNX],320
        MOV     WORD [SCRNY],200
        MOV     DWORD [VRAM],000a0000H
;--------------------------------------------------------------------------
keystatus:
        MOV     AH,02H
        INT     16H             
        MOV     [LEDS],AL
        MOV     AL,0ffH
        OUT     21H,AL
        NOP      
        CLI                                      
;--------------------------------------------------------------------------
        CALL    waitkbdout
        MOV     AL,0d1H
        OUT     64H,AL
        CALL    waitkbdout
        MOV     AL,0dfH          
        OUT     60H,AL
        CALL    waitkbdout
;-------------------------------------------------------------------------
        LGDT    [GDTR0]          
        MOV     EAX,CR0
        AND     EAX,7fffffffH
        OR      EAX,00000001H 
        MOV     CR0,EAX
        JMP     FLUSH
FLUSH:
        MOV     AX,0008H           
        MOV     DS,AX
        MOV     ES,AX
        MOV     FS,AX
        MOV     GS,AX
        MOV     SS,AX
;----------------------------------------------------------------------
        MOV     ESI,bootpack 
        MOV     EDI,BOTPAK       
        MOV     ECX,512*1024/4
        CALL    memcpy
;----------------------------------------------------------------------
        MOV     EBX,BOTPAK
        MOV     ECX,[EBX+16]
        ADD     ECX,3            
        SHR     ECX,2            
        JZ      skip             
        MOV     ESI,[EBX+20] 
        ADD     ESI,EBX
        MOV     EDI,[EBX+12] 
        CALL    memcpy
skip:
        MOV     ESP,[EBX+12] 
        JMP     DWORD 2*8:0000001bH
;---------------------------------------------------------------------
waitkbdout:
        IN      AL,64H
        AND     AL,02H
        JNZ     waitkbdout       
        RET
;---------------------------------------------------------------------
memcpy:
        MOV     EAX,[ESI]
        ADD     ESI,4
        MOV     [EDI],EAX
        ADD     EDI,4
        SUB     ECX,1
        JNZ     memcpy           
        RET
;--------------------------------------------------------------------
bootpack:
