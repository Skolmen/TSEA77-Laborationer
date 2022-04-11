SETUP:	
	ldi		r16, HIGH(RAMEND)		; Ställer in stackpeckaren
	out		SPH, r16
	ldi		r16, LOW(RAMEND)
	out		SPL, r16

INIT:
	cbi		DDRA, 0					; PortA0 ingång
	ldi		r16, $FF
	out		DDRB, r16				; PortB utgång

	.def	bitcounter=r18
	.def	timer=r16
	.def	input=r20
	.def	output=r22

MAIN_LOOP:
	call	RESET
	call	WAIT_FOR_START_BIT
	call	DISP_NUM
	jmp		MAIN_LOOP
	
RESET:
	ldi		timer, 10				; Halvt tidssteg
	ldi		bitcounter, 8			; Räknare för 4 inkommande bitar
	ldi		input, $00				; Återställer inläsnings registret
	ldi		output, $00				; Återställer data registeret
	ret

WAIT_FOR_START_BIT:
	sbis	PINA, 0					; Om PINA0 är satt går vi till DELAY
	jmp		WAIT_FOR_START_BIT
	call	DELAY
	sbic	PINA, 0					; Om PINA0 är inte satt hoppar vi ur WAIT_FOR_START_BIT "Säkerhetsställer att PINA0 är hittad"
	call	READ_INCOMING_BITS
	ret

READ_INCOMING_BITS:
	ldi		timer, 20				; Helt tidssteg	
	call	DELAY					; Vänta ett tidssteg för den första biten
	in		input, PINA				; Läser in från PINA till r20
	andi	input, $01				; Säkerställer att endast den första biten blir kvar

	lsr		input					; LSR input om input(0) är 1 kommer  den skickas till carry
	ror		output					; Tar carryn och lägger den som MSB på output

	dec		bitcounter
	brne	READ_INCOMING_BITS
	;swap	output					; Vid 4-bitars byter nibblarna plats

	ret

DISP_NUM:							; Skriver ut siffran till HEX-display
	out		PORTB, output
	ret

DELAY:
	sbi     PORTB, 7
DELAY_OUTER_LOOP:
	ldi     r17, $1F
DELAY_INNER_LOOP:
	dec     r17
	brne    DELAY_INNER_LOOP
	dec     timer
	brne    DELAY_OUTER_LOOP
	cbi     PORTB, 7
	ret
