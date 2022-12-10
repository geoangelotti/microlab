DATA SEGMENT 
	MSG1 db 0dh, "GIVE 3 HEX DIGITS: ","$"    
	MSG2 db "DECIMAL:","$"
DATA ENDS
CODE SEGMENT
	ASSUME CS : CODE, DS : DATA 

READ MACRO 		   ; Macroentoli diavasmatos
    MOV AH, 8      ; Diakoph 21H (INT 21h) me timh toy AH 8 
    INT 21h 	   ; shmainei diavase apo plhktrologio (an AH=1 emfanizei kiolas)
ENDM

PRINT MACRO CHAR 	
    MOV DL, CHAR	
    MOV AH, 2		
    INT 21h 
ENDM		

EXIT MACRO 		
    MOV AX, 4C00H 	
    INT 21h 
ENDM  

PRINT_STR	MACRO CHAR
	PUSH AX
	PUSH DX
	MOV DX,OFFSET CHAR
	MOV AH,9
	INT 21H
	POP DX
	POP AX
ENDM     
     
MAIN PROC NEAR    
    START:
    MOV AX,DATA
	MOV DS,AX
    PRINT_STR MSG1 
    
    MOV DI,5700H
    MOV CX,3d   
    
    HEX_KEYB:           
        READ
        CMP AL,30H
        JL HEX_KEYB
        CMP AL,39H    ;an einai apo 0 mexri 9
        JLE DIGIT
        CMP AL,41H    
        JL HEX_KEYB
        CMP AL,46H    ;an einai apo A mexri F
        JLE CAPITAL   
        CMP AL,61H    ;an einai apo a mexri f
        JL HEX_KEYB
        CMP AL,66H
        JLE LOWERCASE
        JMP HEX_KEYB 
        
    DIGIT: 
        MOV [DI+3],AL
        SUB AL,30H
        JMP STORE_NUM
    
    CAPITAL:
        MOV [DI+3],AL
        SUB AL,37H
        JMP STORE_NUM
    
    LOWERCASE:
        SUB AL,20H
        MOV [DI+3],AL
        SUB AL,37H
        JMP STORE_NUM
        
    STORE_NUM:   
        MOV [DI],AL
        ADD DI,01H
        LOOP HEX_KEYB
        
    MOV DI,5700H    
    CHECK1:            ;elegxos ean h eisodos mou einai D11
        MOV AL,[DI]
        CMP AL,0DH
        JNE CONTINUE
        MOV AL,[DI+1]
        CMP AL,01H
        JNE CONTINUE
        MOV AL,[DI+2]
        CMP AL,01H
        JNE CONTINUE
        EXIT
         
    CONTINUE:
    MOV DI,5700H
    
    PRINT_THE_NUMBERS1: 
        MOV AL,[DI+3]
        PRINT AL 
        MOV AL,[DI+4]
        PRINT AL 
        MOV AL,00101110b
        PRINT AL
        MOV AL,[DI+5]
        PRINT AL 
        
    PRINT 0AH     
    PRINT 0DH    
    PRINT_STR MSG2    
    MOV DI,5700H 
    
    MOV BL,[DI]
    MOV CL,04H
    ROL BL,CL
    ADD BL,[DI+1]    
    
    CALL PRINT_DEC
    MOV AL,2EH
    PRINT AL
    
    MOV BL,[DI+2]
    LOOPI:
        MOV AL,0AH  ;pollaplasiazw epi 10
        MUL BL
        MOV BL,10h	; kai diairoume dia 16
        DIV BL		; gia na metatrepsoume to 16adiko se 10adiko
        PUSH AX			
        ADD AL,30h
        PRINT AL
        POP AX
        MOV BL,AH
        CMP BL,00h
        JNE LOOPI
        PRINT 0Ah                    
        
    JMP START
     
    PRINT_DEC:
            PUSH BX  
   	        MOV DH,100d
    	    MOV AL,BL
   	        MOV AH,00h
    	    DIV DH 
    	    ADD AL,30h 
    	    PUSH AX
    	    PRINT AL
    	    POP AX 
   	        MOV AL,AH
    	    MOV AH,00h  
   	        MOV DH,10d
   	        DIV DH
    	    ADD AL,30h 
    	    PUSH AX
    	    PRINT AL
    	    POP AX 
    	    ADD AH,30h
    	    PRINT AH
            POP BX
    	    RET    

ENDP MAIN
CODE ENDS
    END MAIN     
ret




