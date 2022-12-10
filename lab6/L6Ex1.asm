.include "m16def.inc"

.def temp = r16
.def temp2 = r17
.def temp3 = r18

.def res0 = r19
.def res1 = r20
.def res2 = r21
.def res3 = r22

.def result = r23

reset:
	ldi temp, low(RAMEND)	;initialize stack pointer
	out SPL, temp
	ldi temp, high(RAMEND)
	out SPH, temp
	
	ser temp
	out DDRB, temp			;PORTB is output
	clr temp
	out PORTB, temp			;initially, PORTB LEDs are off
	out DDRA, temp			;PORTA as input
	out DDRC, temp			;PORTC as input

start:
	in temp, PINA			;read input

check01:					;XOR gate
	mov temp2, temp
	andi temp2, 0x03		;get PA0, PA1
	cpi temp2, 0x00			;if 00
	breq p50_off
	cpi temp2, 0x03			;if 11
	breq p50_off
	rjmp p50_on
p50_on:
	ldi temp3, 0x01
	rjmp check23
p50_off:
	ldi temp3, 0x00

check23:					;OR gate
	mov temp2, temp
	andi temp2, 0x0C		;get PA2, PA3
	cpi temp2, 0x00			;if 00
	breq b1_off
	rjmp b1_on
b1_on:
	ldi res1, 0x02
	rjmp check45
b1_off:
	ldi res1,0x00

check45:					;NOR gate
	mov temp2, temp
	andi temp2, 0x30		;get PA4, PA5
	cpi temp2, 0x00			;if 00
	breq b2_on
	rjmp b2_off
b2_on:
	ldi res2, 0x04
	rjmp check67
b2_off:
	ldi res2, 0x00

check67:					;NXOR gate
	mov temp2, temp
	andi temp2, 0xC0		;get PA6, PA7
	cpi temp2, 0x00			;if 00
	breq b3_on
	cpi temp2, 0xC0			;if 11
	breq b3_on
	rjmp b3_off
b3_on:
	ldi res3, 0x08
	rjmp p5
b3_off:
	ldi res3,0x00

p5:							;AND gate
	or temp3, res1
	cpi temp3, 0x03			;if 11
	breq b0_on
	rjmp b0_off
b0_on:
	ldi res0, 0x01
	rjmp gates_end
b0_off:
	ldi res0, 0x00

gates_end:
	clr result				;result all leds off

checkC:
	in temp, PINC
	cpi temp, 0x00
	breq display

rev0:
	mov temp2, temp
	andi temp2, 0x01
	cpi temp2, 0x00
	breq rev1
	com res0
	andi res0, 0x01

rev1:
	mov temp2, temp
	andi temp2, 0x02
	cpi temp2, 0x00
	breq rev2
	com res1
	andi res1, 0x02

rev2:
	mov temp2, temp
	andi temp2, 0x04
	cpi temp2, 0x00
	breq rev3
	com res2
	andi res2, 0x04

rev3:
	mov temp2, temp
	andi temp2, 0x08
	cpi temp2, 0x00
	breq rev4
	com res3
	andi res3, 0x08

rev4:
	mov temp2, temp
	andi temp2, 0x10
	cpi temp2, 0x00
	breq rev5
	ori result, 0x10

rev5:
	mov temp2, temp
	andi temp2, 0x20
	cpi temp2, 0x00
	breq rev6
	ori result, 0x20

rev6:
	mov temp2, temp
	andi temp2, 0x40
	cpi temp2, 0x00
	breq rev7
	ori result, 0x40

rev7:
	mov temp2, temp
	andi temp2, 0x80
	cpi temp2, 0x00
	breq display
	ori result, 0x80

display:
	or result, res0
	or result, res1
	or result, res2
	or result, res3

output:
	out PORTB, result
	rjmp start
