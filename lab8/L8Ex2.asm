.include "m16def.inc"

.DSEG
_tmp_: .byte 2

.CSEG
.def temp = r16
.def out_h = r17
.def out_l = r18
.def monades = r19
.def dekades = r20
.def ekato = r21
.def p5 = r22

.org 0x00
rjmp reset

reset:
	ldi  r24, low(RAMEND)	;initialize stack pointer
	out spl, r24
	ldi r24, high(RAMEND)
	out sph, r24
	ldi temp, 0xFC			;output to LCD screen: D7-D2 
	out DDRD, temp
	ldi temp, 0xF0
	out DDRC, temp			;enable keyboard
	rcall lcd_init			;initialize lcd
	clr temp
	out DDRA, temp			;port A is input
init:
	ldi ekato, 0
	ldi dekades, 0
	ldi monades, 0
	ldi temp, 0
	ldi out_h, 0
	ldi out_l, 0
	rcall calc_temp
	rjmp check

FIRST_NUM:
	ldi r24, 10
	rcall scan_keypad_rising_edge
	rcall keypad_to_hex
	cpi r24, 0xFF
	breq FIRST_NUM
	lsl r24
	lsl r24
	lsl r24
	lsl r24
	mov out_h, r24
SECOND_NUM:
	ldi r24, 10
	rcall scan_keypad_rising_edge
	rcall keypad_to_hex
	cpi r24, 0xFF
	breq SECOND_NUM
	add out_h, r24
THIRD_NUM:
	ldi r24, 10
	rcall scan_keypad_rising_edge
	rcall keypad_to_hex
	cpi r24, 0xFF
	breq THIRD_NUM
	lsl r24
	lsl r24
	lsl r24
	lsl r24
	mov out_l, r24
FOURTH_NUM:
	ldi r24, 10
	rcall scan_keypad_rising_edge
	rcall keypad_to_hex
	cpi r24, 0xFF
	breq FOURTH_NUM
	add out_l, r24
	mov r25, out_h
	mov r24, out_l
check:
	ldi r24, 0x01			;clear lcd
	rcall lcd_command
	push r24
	push r25
	ldi r24, low(1530)		;lcd refresh rate
	ldi r25, high(1530)
	rcall wait_usec 
	pop r25
	pop r24
	cpi out_h, 0x80
	breq no_dev
	cpi out_h, 0x00
	breq continue
	cpi out_h, 0xFF
	brne init
continue: 
	cpi out_h, 0xFF
	breq plin
	cpi out_l, 0x00
	breq sign_set			;if temperature is 0 no sign
	ldi r24, '+'
	rcall lcd_data
sign_set:
	mov p5, out_l			;keep 0.5
	andi p5, 0x01
	lsr out_l				;shift right lose 0.5
calculate:
	cpi out_l, 100
	brlo deka
	inc ekato
	subi out_l, 100
deka:
	cpi out_l, 10
	brlo prep
	inc dekades
	subi out_l, 10
	rjmp deka
prep:
	mov monades, out_l
	ldi temp, 0x30
	add ekato, temp
	add dekades, temp
	add monades, temp
	cpi ekato, 0x30
	breq print_deka
	mov r24, ekato
	rcall lcd_data
print_deka:
	cpi dekades, 0x30
	breq print_mona
	mov r24, dekades
	rcall lcd_data
print_mona:
	mov r24, monades
	rcall lcd_data
	cpi p5, 0
	breq celsius
	ldi r24, '.'
	rcall lcd_data
	ldi r24, '5'
	rcall lcd_data
celsius:
	ldi r24, 0xB2			;print Degrees
	rcall lcd_data
	ldi r24, 'C'
	rcall lcd_data
	rjmp init

plin:
	ldi r24, '-'
	rcall lcd_data
	com out_l
	ldi temp, 0x01
	add out_l, temp			;2s complement because negative
	rjmp sign_set

no_dev:
	ldi r24, 'N'
	rcall lcd_data
	ldi r24, 'O'
	rcall lcd_data
	ldi r24, ' '
	rcall lcd_data
	ldi r24, 'D'
	rcall lcd_data
	ldi r24, 'E'
	rcall lcd_data
	ldi r24, 'V'
	rcall lcd_data
	ldi r24, 'I'
	rcall lcd_data
	ldi r24, 'C'
	rcall lcd_data
	ldi r24, 'E'
	rcall lcd_data
	rjmp init
	rjmp FIRST_NUM

keypad_to_hex:
	movw r26 ,r24 
	ldi r24 ,0x0E 
	sbrc r26 ,0 
	ret 
	ldi r24 ,0x00 
	sbrc r26 ,1 
	ret 
	ldi r24 ,0x0F 
	sbrc r26 ,2 
	ret 
	ldi r24 ,0x0D 
	sbrc r26 ,3 
	ret 
	ldi r24 ,0x07
	sbrc r26 ,4 
	ret 
	ldi r24 ,0x08
	sbrc r26 ,5 
	ret 
	ldi r24 ,0x09
	sbrc r26 ,6 
	ret 
	ldi r24 ,0x0C
	sbrc r26 ,7 
	ret 
	ldi r24 ,0x04
	sbrc r27 ,0 
	ret 
	ldi r24 ,0x05
	sbrc r27 ,1 
	ret 
	ldi r24 ,0x06
	sbrc r27 ,2 
	ret 
	ldi r24 ,0x0B
	sbrc r27 ,3 
	ret 
	ldi r24 ,0x01
	sbrc r27 ,4 
	ret 
	ldi r24 ,0x02
	sbrc r27 ,5 
	ret 
	ldi r24 ,0x03
	sbrc r27 ,6 
	ret 
	ldi r24 ,0x0A
	sbrc r27 ,7 
	ret 
	ser r24
	ret

calc_temp:
	rcall one_wire_reset	;initialize and check if anything connected
	cpi r24, 0				;if a device is connected then r24=1 else r24=0
	breq def_out
	ldi r24, 0xCC
	rcall one_wire_transmit_byte
	ldi r24, 0x44
	rcall one_wire_transmit_byte
read_temp:
	rcall one_wire_receive_bit
	sbrs r24, 0
	rjmp read_temp			;wait for the temperature measurement to end
	rcall one_wire_reset
	cpi r24, 0
	breq def_out
	ldi r24, 0xCC
	rcall one_wire_transmit_byte
	ldi r24, 0xBE
	rcall one_wire_transmit_byte
	rcall one_wire_receive_byte
	mov out_l, r24
	ldi r24, 0xBE
	rcall one_wire_transmit_byte
	rcall one_wire_receive_byte
	mov out_h, r25
calc_temp_end:
	ret

def_out:
	ldi out_h, 0x80
	ldi out_l, 0x00
	rjmp calc_temp_end

	wait_usec:   
	sbiw r24 ,1      ; 2 ?????? (0.250 �sec)
	nop; 1 ?????? (0.125 �sec)
	nop; 1 ?????? (0.125 �sec)
	nop; 1 ?????? (0.125�sec)
	nop; 1 ?????? (0.125 �sec)
	brne wait_usec; 1 ? 2 ?????? (0.125 ? 0.250 �sec)
	ret; 4 ??????(0.500 �sec)

wait_msec:
	push r24; 2 ?????? (0.250 �sec)
	push r25; 2 ??????
	ldi r24 , low(998)      ; f??t?se t?? ?ata?.  r25:r24 �e 998 (1 ?????? -0.125 �sec)
	ldi r25 , high(998)     ; 1 ??????(0.125 �sec)
	rcall wait_usec; 3 ?????? (0.375 �sec), p???a?e? s??????? ?a??st???s? 998.375 �sec
	pop r25               ; 2 ?????? (0.250 �sec)
	pop r24               ; 2 ??????
	sbiw r24 , 1          ; 2 ??????
	brne wait_msec; 1 ? 2 ?????? (0.125 ? 0.250 �sec)
	ret; 4 ?????? (0.500 �sec)

one_wire_reset:    
	sbi DDRA ,PA4      ; PA4 configured for output
	cbi PORTA ,PA4     ; 480 �sec reset pulse
	ldi r24 ,low(480)
	ldi r25 ,high(480)
	rcall wait_usec
	cbi DDRA ,PA4      ; PA4 configured for input
	cbi PORTA ,PA4
	ldi r24 ,100       ; wait 100 �sec for devices
	ldi r25 ,0         ; to transmit the presence pulse
	rcall wait_usec
	in r24 ,PINA       ; sample the line
	push r24
	ldi r24 ,low(380) ; wait for 380 �sec 
	ldi r25 ,high(380)
	rcall wait_usec
	pop r25         ; return 0 if no device was
	clr r24            ; detected or 1 else
	sbrs r25 ,PA4
	ldi r24 ,0x01
	ret

one_wire_receive_byte:
	ldi r27 ,8
	clr r26
	loop_:
	rcall one_wire_receive_bit
	lsr r26
	sbrc r24 ,0
	ldi r24 ,0x80
	or r26 ,r24
	dec r27
	brne loop_
	mov r24 ,r26
	ret

one_wire_transmit_byte:
	mov r26 ,r24
	ldi r27 ,8
_one_more_:
	clr r24
	sbrc r26 ,0
	ldi r24 ,0x01
	rcall one_wire_transmit_bit
	lsr r26
	dec r27
	brne _one_more_
	ret

one_wire_receive_bit:
	sbi DDRA ,PA4
	cbi PORTA ,PA4    ; generate time slot
	ldi r24 ,0x02
	ldi r25 ,0x00
	rcall wait_usec
	cbi DDRA ,PA4     ;  release the line
	cbi PORTA ,PA4
	ldi r24 ,10       ; wait 10 �s
	ldi r25 ,0
	rcall wait_usec
	clr r24           ; sample the line
	sbic PINA ,PA4
	ldi r24 ,1
	push r24
	ldi r24 ,49       ; delay 49 �s to meet the standards
	ldi r25 ,0        ; for a minimum of 60 ec time slot 
	rcall wait_usec; and a minimum of 1 �sec recovery time 
	pop r24
	ret

one_wire_transmit_bit:
	push r24          ; save r24
	sbi DDRA ,PA4
	cbi PORTA ,PA4   ; generate time slot
	ldi r24 ,0x02
	ldi r25 ,0x00
	rcall wait_usec
	pop r24          ; output bit
	sbrc r24 ,0
	sbi PORTA ,PA4
	sbrs r24 ,0
	cbi PORTA ,PA4
	ldi r24 ,58       ; wait 58 �sec for the
	ldi r25 ,0        ; device to sample the line
	rcall wait_usec
	cbi DDRA ,PA4 ; recovery time
	cbi PORTA ,PA4
	ldi r24 ,0x01
	ldi r25 ,0x00
	rcall wait_usec
	ret

write_2_nibbles:
	push r24
	in r25 ,PIND
	andi r25 ,0x0F
	andi r24 ,0xF0
	add r24 ,r25
	out PORTD, r24
	sbi PORTD,PD3
	cbi PORTD,PD3
	pop r24
	swap r24
	andi r24 ,0xF0
	add r24 ,r25
	out PORTD ,r24
	sbi PORTD ,PD3
	cbi PORTD ,PD3
	ret

lcd_data:
	sbi PORTD,PD2
	rcall write_2_nibbles
	ldi r24 ,43
	ldi r25 ,0
	rcall wait_usec
	ret

lcd_command: 
	cbi PORTD,PD2
	rcall write_2_nibbles
	ldi r24 ,39
	ldi r25 ,0
	rcall wait_usec
	ret

lcd_init:
	ldi r24 ,40
	ldi r25 ,0
	rcall wait_msec
	ldi r24 ,0x30
	out PORTD ,r24
	sbi PORTD,PD3
	cbi PORTD,PD3
	ldi r24 ,39
	ldi r25 ,0
	rcall wait_usec
	ldi r24 ,0x30
	out PORTD ,r24
	sbi PORTD ,PD3
	cbi PORTD ,PD3
	ldi r24 ,39
	ldi r25 ,0
	rcall wait_usec
	ldi r24 ,0x20
	out PORTD ,r24
	sbi PORTD ,PD3
	cbi PORTD ,PD3
	ldi r24 ,39
	ldi r25 ,0
	rcall wait_usec
	ldi r24 ,0x28
	rcall lcd_command
	ldi r24 ,0x0c
	rcall lcd_command
	ldi r24 ,0x01
	rcall lcd_command
	ldi r24 ,low(1530)
	ldi r25 ,high(1530)
	rcall wait_usec
	ldi r24 ,0x06
	rcall lcd_command
	ret

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
