.include "m16def.inc"
.def num = r16
.def status = r17
.def temp = r18
.org 0x00
rjmp RESET

RESET:
ldi status, LOW(RAMEND)
out SPL, status
ldi status, HIGH(RAMEND)
out SPH, status
clr status
out DDRA, status
;out PORTA, status
ldi status, 0xfc
out DDRD, status ; PD2-7 as output (LCD screen).
rcall lcd_init ; Initialize LCD screen.

LOOP:
ldi r24, LOW(100)
ldi r25, HIGH(100)
rcall wait_msec
rcall wipe_screen ; Perform screen wipe.
in status, PINA ; Read number in 1’s complement form from PORTA.
ldi r24,'0'
sbrc status,7
ldi r24,'1'
rcall lcd_data
ldi r24,'0'
sbrc status,6
ldi r24,'1'
rcall lcd_data
ldi r24,'0'
sbrc status,5
ldi r24,'1'
rcall lcd_data
ldi r24,'0'
sbrc status,4
ldi r24,'1'
rcall lcd_data
ldi r24,'0'
sbrc status,3
ldi r24,'1'
rcall lcd_data
ldi r24,'0'
sbrc status,2
ldi r24,'1'
rcall lcd_data
ldi r24,'0'
sbrc status,1
ldi r24,'1'
rcall lcd_data
ldi r24,'0'
sbrc status,0
ldi r24,'1'
rcall lcd_data
ldi r24,'='
rcall lcd_data
cpi status, 0xff
breq zero_case
cpi status, 0x00
breq zero_case

; Assume status is negative.
ldi r24, '-' ; Put minus sign in r24.;-
cpi status, 0 ; Is status < 0 ?
brmi NEG1 ; yes: Skip negation.
com status ; no : Negate it-neg
ldi r24, '+' ; Put plus sign in r24.+

NEG1: ; INVARIANT: At this point, -128 <= status <= -100.
rcall lcd_data ; Echo r24 on screen [sign digit].
ldi r24, '1' ; Put '1' in r24 [hundreds digit].
mov num, status ; Save status.
ldi temp, 100 ; Add 64h = 100d to status.
add status, temp
brmi NEG2 ; Leave '1' in the hundreds place if status < 0...
breq NEG2 ; or status = 0.
ldi r24, '0' ; Put '0' in r24 [hundreds digit].
mov status, num ; Restore status.

NEG2:
cpse status, num ; Skip showing hundreds digit if it is '0'.
rcall lcd_data ; Echo r24 on screen [hundreds digit].
ldi temp, 10
clr num ; Zero decades counter.

DECLOOP: ; INVARIANT: At this point, -100 < status <= 0
cpi status, 0 ; Abort decades counting if status = 0.
breq NEG3 
cpi status, 0xf7 ; Is status < -9 (F7h = -9d)?
brcc NEG3 ; no : Break loop.
add status, temp ; yes: Add 10 to status
inc num ; increase decade counter.
rjmp DECLOOP ; and loop.

NEG3: ; INVARIANT: At this point -10 < status <= 0
mov r24, num ; Put decades counter to r24.
ldi temp, 48
add r24, temp ; Convert r24 to ASCII [decades digit].
push r24
rcall lcd_data ; Echo r24 on screen [decades digit].
pop r24
com status ; Convert status to positive.
mov r24, status ; Put units counter to r24.
add r24, temp ; Convert r24 to ASCII [units digit].
rcall lcd_data ; Echo r24 on screen [units digit].
;pop temp ; Restore initial number from stack.

SPIN:
in status, PINA ; Get new number.
cp status, temp ; Compare old and new number.
breq SPIN ; Loop while number hasn't changed.
rjmp LOOP ; Loop endlessly

zero_case:
	ldi r24, '0'
	rcall lcd_data
	rjmp SPIN
	


; == wait_usec ==
; Treats r24 as a 8-bit value K.
; Causes a delay almost equal to K usec.
; MODIFIES: r24, r25.
wait_usec:
sbiw r24, 1
nop
nop
nop
nop
brne wait_usec
ret
; == wait_msec ==
; Treats (r25:r24) as a 16-bit value K.
; Causes a delay almost equal to K msec. Calls wait_usec.
; MODIFIES: r24, r25, SPL, SPH.
wait_msec:
push r24 ; Save r24 on the stack.
push r25 ; Save r25 on the stack.
ldi r24, low(998) ; (r25:r24) = 998
ldi r25, high(998)
rcall wait_usec ; Cause a ~1msec delay.
pop r25 ; Restore r25 from stack.
pop r24 ; Restore r24 from stack.
sbiw r24, 1 ; Decrease (r25:r24).
brne wait_msec ; Loop until (r25:r24) == 0.
ret ; Return to caller.
; == write_2_nibbles ==
; Sends the byte in r24 to the LCD screen.
; MODIFIES: r24, (r25).
write_2_nibbles:
push r25
push r24
in r25, PIND
andi r25, 0x0f
andi r24, 0xf0
add r24, r25
out PORTD, r24
sbi PORTD, PD3
cbi PORTD, PD3
pop r24
swap r24
andi r24, 0xf0
add r24, r25
out PORTD, r24
sbi PORTD, PD3
cbi PORTD, PD3
pop r25
ret
; == lcd_data ==
; Treats r24 as a data byte.
; Sends the data byte to the LCD screen.
; MODIFIES: r24, r25.
lcd_data:
sbi PORTD, PD2
rcall write_2_nibbles
ldi r24, 43
ldi r25,0
rcall wait_usec
ret
; == lcd_command ==
; Treats r24 as a command byte.
; Sends the command byte to the LCD screen.
; MODIFIES: r24, r25.
lcd_command:
cbi PORTD, PD2
rcall write_2_nibbles
ldi r24, 39
ldi r25, 0
rcall wait_usec
ret
; == lcd_init ==
; This routine initializes the LCD screen.
; MODIFIES: r25:r24.
lcd_init:
ldi r24, 40
ldi r25, 0
rcall wait_msec
ldi r24, 0x30
out PORTD, r24
sbi PORTD, PD3
cbi PORTD, PD3
ldi r24, 39
ldi r25, 0
rcall wait_usec
ldi r24, 0x30
out PORTD, r24
sbi PORTD, PD3
cbi PORTD, PD3
ldi r24, 39
ldi r25, 0
rcall wait_usec
ldi r24, 0x20
out PORTD, r24
sbi PORTD, PD3
cbi PORTD, PD3
ldi r24, 39
ldi r25, 0
rcall wait_usec
ldi r24, 0x28
rcall lcd_command
ldi r24, 0x0c
rcall lcd_command
ldi r24, 0x01
rcall lcd_command
ldi r24, low(1530)
ldi r25, high(1530)
ldi r24, 0x06
rcall lcd_command
ret

; == wipe_screen ==
; Wipes the LCD screen. Assumes screen controller has initialized correctly.
; Note: Approx. 1.5sec delay caused as a result of command processing.
; MODIFIES: r24, r25
wipe_screen:
ldi r24, 0x01 ; Issue a screen-wipe command.
rcall lcd_command ;
ldi r24, low(1530) ; Delay for 1.5msec until command is processed.
ldi r25, high(1530)
rcall wait_usec
ret ; Return to caller.
