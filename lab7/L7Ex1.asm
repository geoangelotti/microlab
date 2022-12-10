.include "m16def.inc"

.def temp=r16
.def flag=r17 ; 0 for wrong - 1 for right
.def flag2=r18 ; 0 for less than 3 inputs - 1 for exactly 3 inputs
.def temp3=r19
.DSEG
_tmp_: .byte 2
.CSEG
.org 0x00
rjmp arch

.org 0x10
rjmp timer_overflow_routine


arch:
     ldi r24, LOW(RAMEND) ; Initialise stack pointer.
     out SPL, r24
     ldi r24, HIGH(RAMEND)
     out SPH, r24
     clr r20
     out DDRB, r20 ; PORTB as input.
     ser r20
     out DDRA, r20 ; PORTA as output
	 out DDRD, r20
	 ldi r20,0xf0
	 out DDRC, r20
	 clr temp
	 clr temp3
	 clr r20
	 rcall lcd_init

	 ldi temp,0x04 
     out TIMSK,temp
     ldi temp, 0x00
     out TCCR1B, temp 
     ;rcall lcd_init
     ldi flag,1
     ldi flag2, 0

start:
	 in temp, PINB
     cpi temp, 0
     breq start
set_timer:
     ;set timer = 5sec
     ldi temp,0x67
     out TCNT1H,temp
     ldi temp,0x69
     out TCNT1L,temp
     ldi temp,0x05
     out TCCR1B,temp
	 sei
read:
     ldi r24,0x0E
     rcall lcd_command ; set display and cursor, turn off blinking
     ldi r24,39
     ldi r25,0
     rcall wait_usec
	 
first:
     ldi r24,20          
     rcall scan_keypad_rising_edge
     rcall keypad_to_ascii
     cpi r24,0
     breq first  ; check if space
	 push r24
     rcall lcd_data
	 pop r24
     mov temp, r24
     cpi temp, '4'
     brne chflg_1  ; if not 4, then we have wrong number, so we clear the flag
     rjmp second
chflg_1:
     ldi flag,0

second:
     ldi r24,20
     rcall scan_keypad_rising_edge
     rcall keypad_to_ascii
     cpi r24,0
     breq second
     push r24
     rcall lcd_data
     pop r24
     mov temp, r24
     cpi temp, '1'
     brne chflg_2
     rjmp third
     
chflg_2: 
     ldi flag,0
third:
     ldi r24,20
     rcall scan_keypad_rising_edge
     rcall keypad_to_ascii
     cpi r24,0
     breq third
     push r24
     rcall lcd_data
     pop r24
     ldi flag2,1
     mov temp, r24
     cpi temp, '1'
     brne chflg_3
     rjmp check
chflg_3:
     ldi flag,0

check:
     cpi flag,0
     breq alarm_on
     cpi flag2,0
     breq alarm_on

alarm_off:
     ldi r24,0x0C
     rcall lcd_command
     ldi r24,39
     ldi r25,0
     rcall wait_usec
     ldi r24,0x01
     rcall lcd_command
     ldi r24,low(1530)
     ldi r25,high(1530)
     rcall wait_usec
     ldi r24,0x41
     rcall lcd_data
     ldi r24,0x4C
     rcall lcd_data
     ldi r24,0x41
     rcall lcd_data
     ldi r24,0x52
     rcall lcd_data
     ldi r24,0x4D
     rcall lcd_data
     ldi r24,0x20
     rcall lcd_data
     ldi r24,0x4F
     rcall lcd_data
     ldi r24,0x46
     rcall lcd_data
     ldi r24,0x46
     rcall lcd_data
check_again:
	 in  temp3, PINB
	 cpi temp3, 0x00
	 breq check_again
	 ldi r24, 1
	 rcall lcd_command
	 ldi r24, 0X0E
	 rcall lcd_command
	 rcall lcd_init
	 ldi flag, 1
	 clr flag2
	 rjmp start

alarm_on:
     rcall fun_alarm_on

end:
     rjmp end
     
fun_alarm_on:
     ldi r24,0x0C
     rcall lcd_command
     ldi r24,39
     ldi r25,0
     rcall wait_usec
     ldi r24,0x01
     rcall lcd_command
     ldi r24,low(1530)
     ldi r25,high(1530)
     rcall wait_usec
     ldi r24,0x41
     rcall lcd_data
     ldi r24,0x4C
     rcall lcd_data
     ldi r24,0x41
     rcall lcd_data
     ldi r24,0x52
     rcall lcd_data
     ldi r24,0x4D
     rcall lcd_data
     ldi r24,0x20
     rcall lcd_data
     ldi r24,0x4F
     rcall lcd_data
     ldi r24,0x4E
     rcall lcd_data

SHOW:
     ser temp
     out PORTA,temp
     ldi r24,low(400)
     ldi r25,high(400)
     rcall wait_msec
     clr temp
     out PORTA,temp
     ldi r24,low(100)
     ldi r25,high(100)
     rcall wait_msec
     rjmp SHOW
     ret


timer_overflow_routine:
     ldi r24,20
     ldi r25,0
     rcall wait_msec
     cpi flag,0
     breq PASSWORD_Wrong
     cpi flag2,0
     breq PASSWORD_Wrong
     rjmp end_timer
PASSWORD_Wrong:
     rcall fun_alarm_on
end_timer:
     reti

scan_keypad_rising_edge:
 mov r22 ,r24
 rcall scan_keypad
 push r24
 push r25
 mov r24 ,r22
 ldi r25 ,0
 rcall wait_msec
 rcall scan_keypad
 pop r23
 pop r22
 and r24 ,r22
 and r25 ,r23
 ldi r26 ,low(_tmp_)
 ldi r27 ,high(_tmp_)
 ld r23 ,X+
 ld r22 ,X
 st X ,r24
 st -X ,r25
 com r23
 com r22
 and r24 ,r22
 and r25 ,r23
 ret

scan_keypad:
 ldi r24 ,0x01
 rcall scan_row
 swap r24
 mov r27 ,r24
 ldi r24 ,0x02
 rcall scan_row
 add r27 ,r24
 ldi r24 ,0x03
 rcall scan_row
 swap r24
 mov r26 ,r24
 ldi r24 ,0x04
 rcall scan_row
 add r26 ,r24
 movw r24 ,r26
 ret

keypad_to_ascii:
 movw r26 ,r24
 ldi r24 ,'*'
 sbrc r26 ,0
 ret
 ldi r24 ,'0'
 sbrc r26 ,1
 ret
 ldi r24 ,'#'
 sbrc r26 ,2
 ret
 ldi r24 ,'D'
 sbrc r26 ,3
 ret
 ldi r24 ,'7'
 sbrc r26 ,4
 ret
 ldi r24 ,'8'
 sbrc r26 ,5
 ret
 ldi r24 ,'9'
 sbrc r26 ,6
 ret
 ldi r24 ,'C'
 sbrc r26 ,7
 ret
 ldi r24 ,'4'
 sbrc r27 ,0
 ret
 ldi r24 ,'5'
 sbrc r27 ,1
 ret
 ldi r24 ,'6'
 sbrc r27 ,2
 ret
 ldi r24 ,'B'
 sbrc r27 ,3
 ret
 ldi r24 ,'1'
 sbrc r27 ,4
 ret
 ldi r24 ,'2'
 sbrc r27 ,5
 ret
 ldi r24 ,'3'
 sbrc r27 ,6
 ret
 ldi r24 ,'A'
 sbrc r27 ,7
 ret
 clr r24
 ret

wait_msec:
 push r24
 push r25
 ldi r24 , low(998)
 ldi r25 , high(998)
 rcall wait_usec
 pop r25
 pop r24
 sbiw r24 , 1
 brne wait_msec
 ret

wait_usec:
 sbiw r24 ,1
 nop
 nop
 nop
 nop
 brne wait_usec 
 ret

scan_row:
 ldi r25 ,0x08
back_: lsl r25
 dec r24
 brne back_
 out PORTC ,r25
 nop
 nop
 in r24 ,PINC
 andi r24 ,0x0f
 ret 


write_2_nibbles:
     push r24 ; στέλνει τα 4 MSB
     in r25 ,PIND ; διαβάζονται τα 4 LSB και τα ξαναστέλνουμε
     andi r25 ,0x0f ; για να μην χαλάσουμε την όποια προηγούμενη κατάσταση
     andi r24 ,0xf0 ; απομονώνονται τα 4 MSB και
     add r24 ,r25 ; συνδυάζονται με τα προϋπάρχοντα 4 LSB
     out PORTD ,r24 ; και δίνονται στην έξοδο
     sbi PORTD ,PD3 ; δημιουργείται παλμός Enable στον ακροδέκτη PD3
     cbi PORTD ,PD3 ; PD3=1 και μετά PD3=0
     pop r24 ; στέλνει τα 4 LSB. Ανακτάται το byte.
     swap r24 ; εναλλάσσονται τα 4 MSB με τα 4 LSB
     andi r24 ,0xf0 ; που με την σειρά τους αποστέλλονται
     add r24 ,r25
     out PORTD ,r24
     sbi PORTD ,PD3 ; Νέος παλμός Enable
     cbi PORTD ,PD3
ret

lcd_data:
     sbi PORTD ,PD2 ; επιλογή του καταχωρήτη δεδομένων (PD2=1)
     rcall write_2_nibbles ; αποστολή του byte
     ldi r24 ,43 ; αναμονή 43μsec μέχρι να ολοκληρωθεί η λήψη
     ldi r25 ,0 ; των δεδομένων από τον ελεγκτή της lcd
     rcall wait_usec
ret

lcd_command:
     cbi PORTD ,PD2 ; επιλογή του καταχωρητή εντολών (PD2=1)
     rcall write_2_nibbles ; αποστολή της εντολής και αναμονή 39μsec
     ldi r24 ,39 ; για την ολοκλήρωση της εκτέλεσης της από τον ελεγκτή της lcd.
     ldi r25 ,0 ; ΣΗΜ.: υπάρχουν δύο εντολές, οι clear display και return home,
     rcall wait_usec ; που απαιτούν σημαντικά μεγαλύτερο χρονικό διάστημα.
ret


lcd_init:
ldi r24 ,40 ; Όταν ο ελεγκτής της lcd τροφοδοτείται με
ldi r25 ,0 ; ρεύμα εκτελεί την δική του αρχικοποίηση.
rcall wait_msec ; Αναμονή 40 msec μέχρι αυτή να ολοκληρωθεί.
ldi r24 ,0x30 ; εντολή μετάβασης σε 8 bit mode
out PORTD ,r24 ; επειδή δεν μπορούμε να είμαστε βέβαιοι
 sbi PORTD ,PD3 ; για τη διαμόρφωση εισόδου του ελεγκτή
cbi PORTD ,PD3 ; της οθόνης, η εντολή αποστέλλεται δύο φορές
ldi r24 ,39
ldi r25 ,0 ; εάν ο ελεγκτής της οθόνης βρίσκεται σε 8-bit mode
rcall wait_usec ; δεν θα συμβεί τίποτα, αλλά αν ο ελεγκτής έχει διαμόρφωση
 ; εισόδου 4 bit θα μεταβεί σε διαμόρφωση 8 bit
 ldi r24 ,0x30
out PORTD ,r24
 sbi PORTD ,PD3
cbi PORTD ,PD3
ldi r24 ,39
ldi r25 ,0
rcall wait_usec
ldi r24 ,0x20 ; αλλαγή σε 4-bit mode
out PORTD ,r24
 sbi PORTD ,PD3
cbi PORTD ,PD3
ldi r24 ,39
ldi r25 ,0
rcall wait_usec
 ldi r24 ,0x28 ; επιλογή χαρακτήρων μεγέθους 5x8 κουκίδων
 rcall lcd_command ; και εμφάνιση δύο γραμμών στην οθόνη
ldi r24 ,0x0c ; ενεργοποίηση της οθόνης, απόκρυψη του κέρσορα
 rcall lcd_command
 ldi r24 ,0x01 ; καθαρισμός της οθόνης
rcall lcd_command
ldi r24 ,low(1530)
ldi r25 ,high(1530)
rcall wait_usec
 ldi r24 ,0x06 ; ενεργοποίηση αυτόματης αύξησης κατά 1 της διεύθυνσης
rcall lcd_command ; που είναι αποθηκευμένη στον μετρητή διευθύνσεων και
 ; απενεργοποίηση της ολίσθησης ολόκληρης της οθόνης
ret
