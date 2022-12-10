.include "m16def.inc"

.def temp = r16
.def input = r17
.def counter = r18

.org 0x00
rjmp reset

reset:
	ldi temp, LOW(RAMEND)
	out SPL, temp
	ldi temp, HIGH(RAMEND)
	out SPH, temp
	clr temp
	out DDRA, temp			;port A for the input
	ser temp
	out DDRB, temp			;port B for the output

flash:
	rcall on
	ldi r24, low(200)		;for 200 msecs
	ldi r25, high(200)
	rcall wait_msec
	ldi counter, 0
onloop:
	in input, PINA
	andi input, 0x0F		;Keep 4 LSB
	cp input, counter
	brlt decay
	ldi r24, low(200)		;for 200 msecs
	ldi r25, high(200)
	rcall wait_msec
	inc counter
	rjmp onloop
decay:
	rcall off
	ldi r24, low(200)		;for 200 msecs
	ldi r25, high(200)
	rcall wait_msec
	ldi counter, 0
offloop:
	in input, PINA
	andi input, 0xF0		;Keep 4 MSB
	lsr input				;Shift right 4 times
	lsr input
	lsr input
	lsr input
	cp input, counter
	brlt loopback
	ldi r24, low(200)		;for 200 msecs
	ldi r25, high(200)
	rcall wait_msec
	inc counter
	rjmp offloop
loopback:
	rjmp flash

on:
	ser temp
	out PORTB, temp
	ret

off:
	clr temp
	out PORTB, temp
	ret

wait_usec:
	sbiw r24 ,1 ; 2 cycles (0.250 �sec)
	nop ; 1 cycles (0.125 �sec)
	nop ; 1 cycles (0.125 �sec)
	nop ; 1 cycles (0.125 �sec)
	nop ; 1 cycles (0.125 �sec)
	brne wait_usec ; 1 or 2 cycles (0.125 or 0.250 �sec)
	ret ; 4 cycles (0.500 �sec)

wait_msec:
	push r24 ; 2 cycles (0.250 �sec)
	push r25 ; 2 cycles
	ldi r24 , low(998) ; r25:r24 �e 498 (1 cycles - 0.125 �sec)
	ldi r25 , high(998) ; 1 cycles (0.125 �sec)
	rcall wait_usec ; 3 cycles (0.375 �sec), 498.375 �sec
	pop r25 ; 2 cycles (0.250 �sec)
	pop r24 ; 2 cycles
	sbiw r24 , 1 ; 2 cycles
	brne wait_msec ; 1 or 2 cycles (0.125 of 0.250 �sec)
	ret ; 4 cycles (0.500 �sec)
