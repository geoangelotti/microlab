.include "m16def.inc"
; arxikopoihsh diakophs
.org 0x0
rjmp reset
.org 0x4 ; h INT1
rjmp ISR1 ; orizetai sto 0x4

; orisma metablhtwn
.def temp = r16
.def n_counter= r17
.def inter = r18

RESET:
	ldi temp, low(RAMEND) ; Initialize stack pointer.
	out SPL, temp
	ldi temp, high(RAMEND)
	out SPH, temp
	; upoloipes arxikopoihseis thirwn
	ldi r24 ,( 1 << ISC11) | ( 1 << ISC10)
	out MCUCR , r24
	ldi r24 ,( 1 << INT1)
	out GICR , r24
	sei ; arxikopoiseis eiswdwn eksodwn
	clr temp
	out DDRD, temp ; PORTD as input.
	ser temp
	out DDRB, temp ; PORTB as output.
	ser temp
	out DDRA, temp ; PORTA as output for inter of INT0.
	clr inter ; set interrupt n_counter=0
	clr n_counter ; initialize n_counter = 0

LOOP:
	out PORTB,n_counter ; show n_counter on portB
	ldi r24, low(200)
	ldi r25, high(200)
	rcall wait_msec ; Delay for 200msec.
	inc n_counter
	rjmp LOOP

ISR1:
	push n_counter ; save n_counter
	in n_counter,SREG ; and SREG
	push n_counter
	in temp,PIND ; read frop pinD
	sbrs temp,7
	rjmp END
	inc inter ; increase interruptions n_counter
	out PORTA,inter ; and print it in A leds

END:
	pop n_counter
	out SREG,n_counter
	pop n_counter
	reti

wait_msec:
	push r24 ; Save r24 on the stack.
	push r25 ; Save r25 on the stack.
	ldi r24, low(998) ; (r25:r24) = 998
	ldi r25, high(998) ; ...
	rcall wait_usec ; Cause a ~1msec delay.
	pop r25 ; Restore r25 from stack.
	pop r24 ; Restore r24 from stack.
	sbiw r24, 1 ; Decrease (r25:r24).
	brne wait_msec ; Loop until (r25:r24) == 0.
	ret ; Return to caller.

wait_usec:
	sbiw r24, 1
	nop
	nop
	nop
	nop
	brne wait_usec
	ret
