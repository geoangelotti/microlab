.include "m16def.inc"

.def reg = r16
.def temp = r17
.def refresh = r18

.org 0x0
rjmp reset
.org 0x4
rjmp int_rout
.org 0x10
rjmp timer1_ovf_int


reset:
	ldi temp,high(RAMEND)					; initialize stack
	out SPH, temp
	ldi temp,low(RAMEND)
	out SPL, temp
	
	ldi reg, ( 1 << ISC11) | ( 1 << ISC10)	; INT1 with positive edge signal
	out MCUCR, reg
	ldi reg, (1 << INT1)					; activate interrupt INT1
	out GICR, reg
	
	ldi reg, (1<<TOIE1)						; activation of overflow interrupt of TCNT1
	out TIMSK, reg							; for timer1
	ldi reg, (1<<CS12) | (0<<CS11) | (1<<CS10) ; CK/1024
	out TCCR1B, reg
	;this means that increase frequency is 8MHz / 1024 = 7.812,5 Hz
	;so for overflow interrupt after 4 sec, timer1 has to count  4 x 7812,5 = 31250 circles
	;but beacause overflow happens at 65.536 circles we have to start from 65.536 - 31250 = 34286 = 0x85EE
	sei										; enable all activated interrupts

	clr temp
	out DDRA,temp ;PORTA as input
	ser temp
	out DDRB,temp ;PORTB as output
	ldi temp,0x00
	out PORTB,temp ;lights->off
	
	clr refresh

main:
	sbis PINA,7 ;skip next command if PA7 = 1, means pressed
	rjmp main
	cpi refresh, $00 ;check if led was already open
	breq ledB0
	
	ser temp
	out PORTB,temp
	ldi r24, low(500)
	ldi r25, high(500)
	rcall wait_msec ; wait 0.5 sec
	rjmp ledB02

ledB0:
	inc refresh
	ldi temp, $01
	out PORTB, temp

	ldi temp, 0x85 ;set the timer
	out TCNT1H,temp
	ldi temp,0xEE
	out TCNT1L,temp

ledB02:
	inc refresh
	ldi temp, $01
	out PORTB, temp

	ldi temp, 0x95 ;set the timer
	out TCNT1H,temp
	ldi temp,0x30
	out TCNT1L,temp
wait:
	sbic PINA,7 ;wait until PINA returns back to 0
	rjmp wait
	rjmp main


timer1_ovf_int:
	clr refresh
	clr temp
	out PORTB,temp ;turn off the leds
	reti

int_rout:
	ldi r24,low(5)
	ldi r25,high(5)
	ldi reg, (1 << INTF1)					; check for misses when the PD3 button is pressed
	out GIFR, reg							; make sure that only one interrupt will be processed
	rcall wait_msec
	in reg, GIFR
	sbrc reg, 6
	rjmp int_rout
	
	push temp
	in temp, SREG	
	push temp
	
	cpi refresh, $00 ;check if led was already open
	breq ledB0_rout
	
	ser temp
	out PORTB,temp
	ldi r24, low(500)
	ldi r25, high(500)
	rcall wait_msec ; wait 0.5 sec
	rjmp lebB0_rout2

ledB0_rout:
	inc refresh
	ldi temp, $01
	out PORTB, temp

	ldi temp, 0x85 ;set the timer
	out TCNT1H,temp
	ldi temp,0xEE
	out TCNT1L,temp
	
	pop temp
	out SREG, temp
	pop temp
	reti

lebB0_rout2:
	inc refresh
	ldi temp, $01
	out PORTB, temp

	ldi temp, 0x95 ;set the timer
	out TCNT1H,temp
	ldi temp,0x30
	out TCNT1L,temp
	
	pop temp
	out SREG, temp
	pop temp
	reti

wait_usec:
	sbiw r24 ,1 		
	nop 				
	nop 				
	nop 				
	nop 				
	brne wait_usec  	
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
