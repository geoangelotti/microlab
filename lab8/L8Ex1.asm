.include "m16def.inc"

.LIST
	.def temp = r16
	.def output_h = r17
	.def output_l = r18

.org 0x00
rjmp reset

reset:
	ldi temp, low(RAMEND)			;Initialize stack pointer
	out SPL, temp
	ldi temp, high(RAMEND)
	out SPH, temp
	
main:
	clr r24
	clr r25
	clr output_h
	clr output_L
	rcall calc_temp
	cpi output_h, 0xff
	breq negative
display:
	ser temp						;Set A as output
	out DDRA, temp
	out PORTA, output_l				;display
	rjmp main

calc_temp:
	rcall one_wire_reset			;reset sensor
	cpi r24,0
	breq no_temp
	ldi r24, 0xCC					;transmit CC
	rcall one_wire_transmit_byte
	ldi r24, 0x44					;transmit 44
	rcall one_wire_transmit_byte
	
read_temp:							;wait for 1 meaning the calculation ended
	rcall one_wire_receive_bit
	sbrs r24, 0
	rjmp read_temp
	rcall one_wire_reset			;reset sensor again
	cpi r24,0
	breq no_temp
	ldi r24, 0xCC
	rcall one_wire_transmit_byte
	ldi r24, 0xBE
	rcall one_wire_transmit_byte
	rcall one_wire_receive_byte		;receive TL
	mov output_l, r24
	ldi r24, 0xBE
	rcall one_wire_transmit_byte
	rcall one_wire_receive_byte		;receive TH
	mov output_h, r24
	mov r25, r24
	mov r24, output_l				;have the result on r25;r24
	rjmp calc_end

no_temp:
	ldi r24, 0x00
	ldi r25, 0x80
	ldi output_l, 0x80
	clr output_h
calc_end:
	ret

negative:
	mov temp, output_l
	andi temp, 0x01					;take the 0.5 temp
	lsr output_l					;shift right
	ori output_l, 0x80				;negative number
	subi output_l, 1				;complementary 1
	lsl output_l					;shift left
	or output_l, temp				;merge with 0.5 temp
	rjmp display
	

	
one_wire_receive_byte: ; Routine: one_wire_receive_byte
; This routine generates the necessary read
; time slots to receives a byte from the wire.
; return value: the received byte is returned in r24.
; registers affected: r27:r26 ,r25:r24
; routines called: one_wire_receive_bit
	ldi r27, 8
	clr r26
loop_:
	rcall one_wire_receive_bit
	lsr r26
	sbrc r24, 0
	ldi r24, 0x80
	or r26, r24
	dec r27
	brne loop_
	mov r24, r26
	ret

one_wire_receive_bit: ; Routine: one_wire_receive_bit
; This routine generates a read time slot across the wire.
; return value: The bit read is stored in the lsb of r24.
; if 0 is read or 1 if 1 is read.
; registers affected: r25:r24
; routines called: wait_usec
	sbi DDRA, PA4
	cbi PORTA, PA4 ; generate time slot
	ldi r24, 0x02
	ldi r25, 0x00
	rcall wait_usec
	cbi DDRA, PA4 ; release the line
	cbi PORTA, PA4
	ldi r24, 10 ; wait 10 ?s
	ldi r25, 0
	rcall wait_usec
	clr r24 ; sample the line
	sbic PINA, PA4
	ldi r24, 1
	push r24
	ldi r24, 49 ; delay 49 ?s to meet the standards
	ldi r25, 0 ; for a minimum of 60 ?sec time slot
	rcall wait_usec ; and a minimum of 1 ?sec recovery time
	pop r24
	ret

one_wire_transmit_byte: ; Routine: one_wire_transmit_byte
; This routine transmits a byte across the wire.
; parameters:
; r24: the byte to be transmitted must be stored here.
; return value: None.
; registers affected: r27:r26 ,r25:r24
; routines called: one_wire_transmit_bit
	mov r26, r24
	ldi r27, 8
_one_more_:
	clr r24
	sbrc r26, 0
	ldi r24, 0x01
	rcall one_wire_transmit_bit
	lsr r26
	dec r27
	brne _one_more_
	ret

one_wire_transmit_bit: ; Routine: one_wire_transmit_bit
; This routine transmits a bit across the wire.
; parameters:
; r24: if we want to transmit 1
; then r24 should be 1, else r24 should
; be cleared to transmit 0.
; return value: None.
; registers affected: r25:r24
; routines called: wait_usec
	push r24 ; save r24
	sbi DDRA, PA4
	cbi PORTA, PA4 ; generate time slot
	ldi r24, 0x02
	ldi r25, 0x00
	rcall wait_usec
	pop r24 ; output bit
	sbrc r24, 0
	sbi PORTA, PA4
	sbrs r24, 0
	cbi PORTA, PA4
	ldi r24, 58 ; wait 58 ?sec for the
	ldi r25, 0 ; device to sample the line
	rcall wait_usec
	cbi DDRA, PA4 ; recovery time
	cbi PORTA, PA4
	ldi r24, 0x01
	ldi r25, 0x00
	rcall wait_usec
	ret

one_wire_reset: ; Routine: one_wire_reset
; This routine transmits a reset pulse across the wire
; and detects any connected devices.
; parameters: None.
; return value: 1 is stored in r24
; if a device is detected, or 0 else.
; registers affected r25:r24
; routines called: wait_usec
	sbi DDRA, PA4 ; PA4 configured for output
	cbi PORTA, PA4 ; 480 ?sec reset pulse
	ldi r24, low(480)
	ldi r25, high(480)
	rcall wait_usec
	cbi DDRA, PA4 ; PA4 configured for input
	cbi PORTA, PA4
	ldi r24, 100 ; wait 100 ?sec for devices
	ldi r25, 0 ; to transmit the presence pulse
	rcall wait_usec
	in r24, PINA ; sample the line
	push r24
	ldi r24, low(380) ; wait for 380 ?sec
	ldi r25, high(380)
	rcall wait_usec
	pop r25 ; return 0 if no device was
	clr r24 ; detected or 1 else
	sbrs r25, PA4
	ldi r24, 0x01
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
