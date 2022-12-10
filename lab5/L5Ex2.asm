.include "m16def.inc"

.def temp = r16
.def check = r17
.def counter = r18
.def inter = r19
.def temp2 = r20
.def temp3 = r21

.org 0x0
rjmp RESET
.org 0x2
rjmp ISR0

RESET:
	ldi temp, low(RAMEND)
	out SPL, temp
	ldi temp, high(RAMEND)
	out SPH, temp
	ldi r24 , (1 << ISC01) | (1 << ISC00)
	out MCUCR, r24
	ldi r24 ,( 1 << INT0 )
	out GICR, r24
	sei
	clr temp
	out DDRA, temp
	ser temp
	out DDRC, temp
	clr counter
LOOPA:
	out PORTB, counter
	ldi r24, low(200)
	ldi r25, high(200)
	rcall wait_msec
	inc counter
	rjmp LOOPA
ISR0:
CHECK1:
	ldi temp,(1 << INTF1)
	out GIFR, temp
	push r24
	push r25
	ldi r24, low(5)
	ldi r25, high(5)
	rcall wait_msec
	pop r25
	pop r24
	in temp ,GIFR
	andi temp, 0x80
	brne CHECK1
	in check, PIND
	sbrs check, 7
	rjmp END
	clr temp2
	clr inter
	in check, PINA
LOOPB:
	sbrc check, 0
	inc inter
	ror check
	inc temp2
	cpi temp2,0x08
	brne LOOPB
	cpi inter, 0x00
	breq END2
	ser temp3
LOOPC:
	lsl temp3 
	dec inter
	cpi inter, 0x00
	brne LOOPC
	com temp3
	out PORTC, temp3
	rjmp END
END2:
	clr temp3
	out PORTC, temp3
END:
	reti

wait_msec:
	push r24
	push r25
	ldi r24, low(998)
	ldi r25, high(998)
	rcall wait_usec
	pop r25
	pop r24
	sbiw r24, 1
	brne wait_msec
	ret
wait_usec:
	sbiw r24, 1
	nop
	nop
	nop
	nop
	brne wait_usec
	ret
