DATA SEGMENT
    MSG1 db "GIVE 2 DECIMAL DIGITS: ","$"
	MSG2 db "OCTAL=","$"  
	NEWLINE		DB 0AH,0DH,'$'          ;new line string
DATA ENDS

CODE SEGMENT
    ASSUME CS : CODE, DS : DATA, ES:DATA
        
PRINT MACRO CHAR
    PUSH AX
    PUSH DX
    MOV DL,CHAR
    MOV AH,2
    INT 21H
    POP DX
    POP AX
ENDM

READ MACRO  
    MOV AH,8
    INT 21H
ENDM  

PRINT_STR MACRO STR
    PUSH AX
    PUSH DX
    MOV DX,OFFSET STR
    MOV AH,9
    INT 21H 
    POP DX
    POP AX
ENDM     

PRINT_OCT MACRO
    MOV CX, 3 ; Loop counter
    CLC ;SET CARRY = 0
    OCTAL_PRINT:

        MOV DL, BL ;
        PUSHF ;STORE CARRY BECAUSE 'AND' MAY
                ;CHANGE IT
        CMP CX,3
        JE PR_1_OCT ;Print first 2 bits
        CMP CX,2
        JE PR_2_OCT ; Print second 3Bit
        AND DL,00000111b ; Print last 3Bit
    CONTIN:
        ADD DL,30H ; ......a......p.. ....f..... .... ASCII
        PRINT DL
        POPF
        LOOP OCTAL_PRINT
        JMP QUITT
    PR_1_OCT:
        AND DL,11000000b
        ROR DL,6
        AND DL,03H
        JMP CONTIN
    PR_2_OCT:
        AND DL,00111000B
        ROR DL,3
        AND DL,07H
        JMP CONTIN
    QUITT:
ENDM          
          
EXIT MACRO
    MOV AX, 4CH
    INT 21h
ENDM

MAIN PROC FAR
    ARCH:
    MOV AX,DATA
	MOV DS,AX
	PRINT_STR MSG1               
    READ_1ST:       ;APOTHIKEVW TIS DEKADES STON BL
        READ
        CMP AL,'Q'
        JE QUIT
        CMP AL,'0'
        JL READ_1ST
        CMP AL,'9'
        JG READ_1ST
        MOV BL,AL  ; AFOU EINAI DEKTO, KRATISE TO
    READ_2ND:      ;APOTHIKEVW TIS MONADES STON DL
        READ
        CMP AL,'Q'
        JE QUIT
        CMP AL,'0'
        JL READ_2ND
        CMP AL,'9'
        JG READ_2ND
        MOV DL,AL
    READ_NEXT:
        READ
        CMP AL,'Q'
        JE QUIT
        CMP AL, 13 ;ELEGXOS GIA ENTER
        JE CONTINUE
        CMP AL,'0'
        JL READ_NEXT
        CMP AL,'9'
        JG READ_NEXT
        MOV BL,DL  ;KANW DEKADES TIS PROHGOYMENES MONADES
        MOV DL,AL  ;KANW MONADES TON ARITHMO POY DIABASA
        JMP READ_NEXT
        
    CONTINUE:
        ;PLEON EXW STON BL TIS DEKADES KAI STON DL TIS MONADES
        PRINT BL
        PRINT DL
        
    ASCII_CONV:
        SUB BL,30H
        SUB DL,30H
        
    FIX:
        MOV AL,10
        MUL BL
        MOV BL, AL
        ADD BL, DL
        PRINT_STR NEWLINE 
        PRINT_STR MSG2
        PRINT_OCT
        PRINT_STR NEWLINE 
    JMP ARCH
    QUIT: EXIT  
       
       
    
    ENDP MAIN
    CODE ENDS
END MAIN

ret