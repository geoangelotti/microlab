.include "m16def.inc"

.LIST
	.def temp = r16
	.def seconds_l = r17
	.def seconds_h = r18
	.def minutes_l = r19
	.def minutes_h = r20
	.def seconds = r21
	.def minutes = r22

.org 0x00
rjmp reset

reset:
	ldi temp, low(RAMEND)		;Initialize stack pointer
	out SPL, temp
	ldi temp, high(RAMEND)
	out SPH, temp
	clr temp					;Set B as input
	out DDRB, temp
	ser temp					;Set D as output
	out DDRD, temp

start:
	rcall lcd_init
	clr seconds
	clr minutes

display_timer:
	clr minutes_h
	clr minutes_l
	clr seconds_h
	clr seconds_l
	push minutes
	push seconds
make_minutes:					;Split minutes to minutes_h and minutes_l
	inc minutes_h
	mov minutes_l, minutes
	subi minutes, 10
	brpl make_minutes
	dec minutes_h
make_seconds:					;Split seconds to seconds_h and seconds_l
	inc seconds_h
	mov seconds_l, seconds
	subi seconds, 10
	brpl make_seconds
	dec seconds_h
	pop seconds
	pop minutes
main:
	rcall lcd_init
	mov r24, minutes_h
	rcall bin_to_ascii
	rcall lcd_data
	mov r24, minutes_l
	rcall bin_to_ascii
	rcall lcd_data
	ldi r24, 0x20
	rcall lcd_data
	ldi r24, 'M'
	rcall lcd_data
	ldi r24, 'I'
	rcall lcd_data
	ldi r24, 'N'
	rcall lcd_data
	ldi r24, ':'
	rcall lcd_data
	mov r24, seconds_h
	rcall bin_to_ascii
	rcall lcd_data
	mov r24, seconds_l
	rcall bin_to_ascii
	rcall lcd_data
	ldi r24, 0x20
	rcall lcd_data
	ldi r24, 'S'
	rcall lcd_data
	ldi r24, 'E'
	rcall lcd_data
	ldi r24, 'C'
	rcall lcd_data

	ldi r24, low(950)
	ldi r25, high(950)
	rcall wait_msec

check_B7:
	in temp, PINB
	cpi temp, 0x80
	breq start
check_B0:
	in temp, PINB
	cpi temp, 0x01
	brne check_B7

increase_time:
	inc seconds
	cpi seconds, 0x3c			;60 seconds
	breq set_minutes
	rjmp display_timer

set_minutes:
	clr seconds
	inc minutes
	cpi minutes, 0x3c			;60 minutes
	breq clear_minutes
	rjmp display_timer

clear_minutes:
	clr minutes
	rjmp display_timer

write_2_nibbles:
;input: r24 - byte
;output: -
;registers used: r24:r25
	push r24		; st???e? ta 4 MSB
	in r25 ,PIND	; d?a�????ta? ta 4 LSB ?a? ta ?a?ast?????�e
	andi r25 ,0x0f	; ??a ?a �?? ?a??s??�e t?? ?p??a p??????�e?? ?at?stas?
	andi r24 ,0xf0	; ap?�??????ta? ta 4 MSB ?a?
	add r24 ,r25	; s??d?????ta? �e ta p???p?????ta 4 LSB
	out PORTD ,r24	; ?a? d????ta? st?? ???d?
	sbi PORTD ,PD3	; d?�?????e?ta? pa?�?? Enable st?? a???d??t? PD3
	cbi PORTD ,PD3	; PD3=1 ?a? �et? PD3=0
	pop r24			; st???e? ta 4 LSB. ??a?t?ta? t? byte.
	swap r24		; e?a???ss??ta? ta 4 MSB �e ta 4 LSB
	andi r24 ,0xf0	; p?? �e t?? se??? t??? ap?st?????ta?
	add r24 ,r25
	out PORTD ,r24
	sbi PORTD ,PD3	; ???? pa?�?? Enable
	cbi PORTD ,PD3
	ret

lcd_data:
;input: r24 - byte
;output: -
;registers used: r24:r25

	sbi PORTD ,PD2			; ep????? t?? ?ata????t? ded?�???? (PD2=1)
	rcall write_2_nibbles	; ap?st??? t?? byte
	ldi r24 ,43				; a?a�??? 43�sec �???? ?a ?????????e? ? ????
	ldi r25 ,0				; t?? ded?�???? ap? t?? e?e??t? t?? lcd
	rcall wait_usec
	ret

lcd_command:
;input: r24 - byte
;output: -
;registers used: r24:r25

	cbi PORTD ,PD2			; ep????? t?? ?ata????t? e?t???? (PD2=1)
	rcall write_2_nibbles	; ap?st??? t?? e?t???? ?a? a?a�??? 39�sec
	ldi r24 ,39				; ??a t?? ????????s? t?? e?t??es?? t?? ap? t?? e?e??t? t?? lcd.
	ldi r25 ,0				; S??.: ?p?????? d?? e?t????, ?? clear display ?a? return home,
	rcall wait_usec			; p?? apa?t??? s?�a?t??? �e?a??te?? ??????? d??st?�a.
	ret

lcd_init:
;input: -
;output: -
;registers used: r24:r25

	ldi r24 ,40			; ?ta? ? e?e??t?? t?? lcd t??f?d?te?ta? �e
	ldi r25 ,0			; ?e?�a e?te?e? t?? d??? t?? a?????p???s?.
	rcall wait_msec		; ??a�??? 40 msec �???? a?t? ?a ?????????e?.
	ldi r24 ,0x30		; e?t??? �et?�as?? se 8 bit mode
	out PORTD ,r24		; epe?d? de? �p????�e ?a e?�aste �?�a???
	sbi PORTD ,PD3		; ??a t? d?a�??f?s? e?s?d?? t?? e?e??t?
	cbi PORTD ,PD3		; t?? ??????, ? e?t??? ap?st???eta? d?? f????
	ldi r24 ,39
	ldi r25 ,0			; e?? ? e?e??t?? t?? ?????? �??s?eta? se 8-bit mode
	rcall wait_usec		; de? ?a s?��e? t?p?ta, a??? a? ? e?e??t?? ??e? d?a�??f?s?
						; e?s?d?? 4 bit ?a �eta�e? se d?a�??f?s? 8 bit
	ldi r24 ,0x30
	out PORTD ,r24
	sbi PORTD ,PD3
	cbi PORTD ,PD3
	ldi r24 ,39
	ldi r25 ,0
	rcall wait_usec
	ldi r24 ,0x20		; a??a?? se 4-bit mode
	out PORTD ,r24
	sbi PORTD ,PD3
	cbi PORTD ,PD3
	ldi r24 ,39
	ldi r25 ,0
	rcall wait_usec
	ldi r24 ,0x28		; ep????? ?a?a?t???? �e?????? 5x8 ?????d??
	rcall lcd_command	; ?a? e�f???s? d?? ??a��?? st?? ?????
	ldi r24 ,0x0c		; e?e???p???s? t?? ??????, ap?????? t?? ???s??a
	rcall lcd_command
	ldi r24 ,0x01		; ?a?a??s�?? t?? ??????
	rcall lcd_command
	ldi r24 ,low(1530)
	ldi r25 ,high(1530)
	rcall wait_usec
	ldi r24 ,0x06		; e?e???p???s? a?t?�at?? a???s?? ?at? 1 t?? d?e????s??
	rcall lcd_command	; p?? e??a? ap????e?�??? st?? �et??t? d?e????se?? ?a?
						; ape?e???p???s? t?? ???s??s?? ????????? t?? ??????
	ret

bin_to_ascii:
;input: r24 - binary of the digit
;output: r24, ascii of the digit
;uses: r24
	push r25
	mov r25, r24
	ldi r24, '0'
	cpi r25, 0
	breq end
	ldi r24, '1'
	cpi r25, 1
	breq end
	ldi r24, '2'
	cpi r25, 2
	breq end
	ldi r24, '3'
	cpi r25, 3
	breq end
	ldi r24, '4'
	cpi r25, 4
	breq end
	ldi r24, '5'
	cpi r25, 5
	breq end
	ldi r24, '6'
	cpi r25, 6
	breq end
	ldi r24, '7'
	cpi r25, 7
	breq end
	ldi r24, '8'
	cpi r25, 8
	breq end
	ldi r24, '9'
	cpi r25, 9
	breq end

end:
	pop r25
	ret

wait_usec: ;each cycle is 1 usec delay
;input: r24 - byte
;output: -
;registers used: r24

	sbiw r24,1
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
	ldi r24,low(998)
	ldi r25,high(998)
	rcall wait_usec
	pop r25
	pop r24
	sbiw r24,1
	brne wait_msec
	ret
