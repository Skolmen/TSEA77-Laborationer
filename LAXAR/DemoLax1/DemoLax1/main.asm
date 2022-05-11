	ldi		r16, HIGH(RAMEND)
	out		SPH, r16
	ldi		r16, LOW(RAMEND)
	out		SPL, r16
	
	call	HW_INIT
	
MAIN_LOOP:
	
	; Ta in det som är på PORTA på r16
	; Jämför med r16 med F
	; OM negativ är talet mindre än F
	; Hoppa till utskrivt och nollställ r17
	; OM postiv eller noll talet är större eller lika med F
	; Sätt r17 till 1
	; Skriv ut r16 till högra displayen PORTB0-3
	; Skriv ut r17 till vänstra displaten PORTD0-3

	clr		r17
	in		r16, PINA
	cpi		r16, 0xA
	brmi	PRINT
	subi	r16, 0xA
	ldi		r17, 0x1
PRINT:
	out		PORTB, r17
	out		PORTD, r16
WAIT:
	in		r18, PINA
	cpi		r18, 0
	breq	WAIT
	rjmp	MAIN_LOOP
	
HW_INIT:
	push	r16
	ldi		r16, $FF
	out		DDRB, r16
	ldi		r16, $FF
	out		DDRD, r16
	pop		r16
	ret	
		