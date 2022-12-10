.include "m16def.inc"

.LIST
	.def temp = r16
	.def result = r17
	.def direction = r18

.org 0x00
rjmp reset

reset:
	ldi temp, low(RAMEND)			;Initialize stack pointer
	out SPL, temp
	ldi temp, high(RAMEND)
	out SPH, temp
start:
	ser temp
	out DDRB, temp
	clr temp
	out DDRA, temp
	ldi result, 0x01
	ldi direction, 0x00
main:
	rcall display
	in temp, PINA
	sbrs temp, 0
	rjmp main
	ldi r25, high(500)
	ldi r24, low(500)
	rcall wait_msec
	sbrc direction, 0
	rjmp down
up:
	cpi result, 0x80
	breq ch_down
	lsl result
	rjmp main
down:
	cpi result, 0x01
	breq ch_up
	lsr result
	rjmp main
ch_up:
	ldi direction, 0x00
	rjmp up
ch_down:
	ldi direction, 0x01
	rjmp down

display:
	out PORTB, result
	ret

wait_usec: ;each cycle is 1 usec delay
;input: r24 - byte
;output: -
;registers used: r24
	sbiw r24, 1
	nop
	nop
	nop
	nop
	brne wait_usec
	ret

wait_msec: ;delay depending on r25r24. 1msec each cycle
;input: r25:r24
;output: -
;registers used: r24:r25
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
