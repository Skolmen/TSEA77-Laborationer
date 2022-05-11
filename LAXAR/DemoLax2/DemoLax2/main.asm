	ldi		r16, HIGH(RAMEND)
	out		SPH, r16
	ldi		r16, LOW(RAMEND)
	out		SPL, r16
	clr		r16

	call	HW_INIT

MAIN_LOOP:

	; Ta in signal p� PORTA0 och PORTA1 0 = uppr�knare, 1 = visa tal
	; V�nta p� insignal
	; Vid porta0 r�kna upp r16
	; Vid porta1 skriv ut r16 till porta1

WAIT:
	sbic	PINA, 0
	rjmp	COUNTER
	sbic	PINA, 1
	rjmp	PRINT
	rjmp	WAIT
	
COUNTER:
	inc		r16
	andi	r16, 0xF
WAIT_FOR_RELEASE_0:
	sbis	PINA, 0
	rjmp	DONE
	rjmp	WAIT_FOR_RELEASE_0

PRINT:
	out		PORTB, r16
WAIT_FOR_RELEASE_1:
	sbis	PINA, 1
	rjmp	DONE
	rjmp	WAIT_FOR_RELEASE_1

DONE:
	rjmp	MAIN_LOOP

HW_INIT:
	push	r16
	ldi		r16, 0xFF
	out		DDRB, r16
	pop		r16
	ret