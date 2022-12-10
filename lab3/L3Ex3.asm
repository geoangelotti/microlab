INCLUDE MACROS3.asm

DATA_SEG SEGMENT
	PEZOI 		DB 15 DUP(?)			;an array for storing non-capital chars
	KEFALAIA	DB 15 DUP(?)			;an array for storing capital char
	ARITHMOI	DB 15 DUP(?)			;an array for storing numbers
	NEWLINE		DB 0AH,0DH,'$'          ;new line string
	MAX1 		DB 30H                  ;max numbers initialised at 0
	MAX2 		DB 30H
    MSG         DB "Give 14 characters:" ,"$"
DATA_SEG ENDS

CODE_SEG SEGMENT
	ASSUME CS:CODE_SEG,DS:DATA_SEG

MAIN PROC FAR
	MOV AX,DATA_SEG
	MOV DS,AX
START:
	MOV BX,0							;BX counts capital chars
	MOV BP,0							;BP counts non-capital chars
	MOV DI,0							;DI counts numbers
	MOV CX,14							;read at most 14 times
    MOV MAX1,30H
	MOV MAX2,30H
	PRINT_STR MSG
ADDR1:
	CALL READ_KEYB		
	CMP AL,0DH
	JE LEAVING							;if pressed enter leave
	CMP AL,3DH
	JE ISON								;if pressed '=' exit
	LOOP ADDR1
	CALL READ_ENTER
LEAVING:
	MOV PEZOI[BP],24H					;add '$' to every sequence for printing
	MOV KEFALAIA[BX],24H
	MOV ARITHMOI[DI],24H
	PRINT_STR NEWLINE
	PRINT_STR ARITHMOI
	PRINT ' '
	PRINT_STR KEFALAIA
	PRINT ' '
	PRINT_STR PEZOI
	PRINT_STR NEWLINE
;now print max numbers
	CMP DI,1							;if no numbers were inserted do nothing. DI contains number of digits inserted by user!
	JL START
	CMP DI,2
	JL LAB1
	PRINT MAX1
	PRINT ' '
LAB1:
    PRINT MAX2
	PRINT_STR NEWLINE
	JMP START
ISON:
	EXIT
MAIN ENDP
	
;accept only enter. Ignore anything else	
READ_ENTER	PROC NEAR
IGNORE2:
	READ
	CMP AL,0DH
	JNZ IGNORE2
	RET
READ_ENTER ENDP
	
;it ignores everything except chars, numbers and space. It stored to mem acceptable input according to what it is	
READ_KEYB	PROC NEAR
IGNORE:
	READ
	CMP AL,3DH				    ;'='
	JE QUIT
	CMP AL,0DH				    ;enter
	JE QUIT
	CMP AL,20H				    ;space
	JNZ NEXT
	PRINT AL
	JMP QUIT
NEXT:
	CMP AL,30H
	JL IGNORE
	CMP AL,39H
	JG NAN
ARITHMOS:
	MOV ARITHMOI[DI],AL			;it was a number. Save it to mem and increase DI
	INC DI
	CMP AL,MAX2                 ;Compare AL, max2
    JL CHKM1                    ;if AL < max2 check AL with max1
    MOV DL,MAX2				    ;else AL > max2
    CMP MAX1,DL                 ;Compare max1, max2
    JG PROCEED                  ;if max1 > max2 keep max1 and replace only max2 
    MOV DL,MAX2                 ;esle max2 < max1
    MOV MAX1,DL                 ;max1 is max2
PROCEED:
    MOV MAX2,AL                 ;and replace max2 with AL 
    JMP ADDR3
CHKM1:                          ;AL < max2
	MOV DL,MAX1
	CMP AL,MAX1
	JL ADDR3                    ;if AL < max1 quit    
	MOV DL,MAX2                 ;else AL > max1 and AL < max2 so max1 is max2 and max2 is AL
	MOV MAX1,DL
	MOV MAX2,AL
ADDR3:
	PRINT AL
	JMP QUIT
NAN:
	CMP AL,41H
	JL IGNORE
	CMP AL,5AH
	JG NOT_KEFALAIO
	MOV KEFALAIA[BX],AL         ;it was a capital. Save it to mem and increase BX
	INC BX
	PRINT AL
	JMP QUIT
NOT_KEFALAIO:
	CMP AL,61H
	JL IGNORE
	CMP AL,7AH
	JG IGNORE
	MOV PEZOI[BP],AL            ;it was a non-capital. Save it to mem and increase BP
	INC BP
	PRINT AL
QUIT:
	RET
READ_KEYB ENDP
	
CODE_SEG ENDS
		END MAIN