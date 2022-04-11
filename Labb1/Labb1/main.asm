SETUP:	
	ldi		r16, HIGH(RAMEND)		; St�ller in stackpeckaren
	out		SPH, r16
	ldi		r16, LOW(RAMEND)
	out		SPL, r16

INIT:
	cbi		DDRA, 0					; PortA0 ing�ng
	ldi		r16, $FF
	out		DDRB, r16				; PortB utg�ng

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
	ldi		bitcounter, 8			; R�knare f�r 4 inkommande bitar
	ldi		input, $00				; �terst�ller inl�snings registret
	ldi		output, $00				; �terst�ller data registeret
	ret

WAIT_FOR_START_BIT:
	sbis	PINA, 0					; Om PINA0 �r satt g�r vi till DELAY
	jmp		WAIT_FOR_START_BIT
	call	DELAY
	sbic	PINA, 0					; Om PINA0 �r inte satt hoppar vi ur WAIT_FOR_START_BIT "S�kerhetsst�ller att PINA0 �r hittad"
	call	READ_INCOMING_BITS
	ret

READ_INCOMING_BITS:
	ldi		timer, 20				; Helt tidssteg	
	call	DELAY					; V�nta ett tidssteg f�r den f�rsta biten
	in		input, PINA				; L�ser in fr�n PINA till r20
	andi	input, $01				; S�kerst�ller att endast den f�rsta biten blir kvar

	lsr		input					; LSR input om input(0) �r 1 kommer  den skickas till carry
	ror		output					; Tar carryn och l�gger den som MSB p� output

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
