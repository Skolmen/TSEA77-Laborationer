//---- Ställer in stackpekaren ----
SETUP:
	ldi		r16,HIGH(RAMEND)
	out		SPH, r16
	ldi		r16, LOW(RAMEND)
	out		SPL, r16

//---- Initierar saker ----
INIT:
	.equ	T=10
	ser		r16
	out		DDRB, r16
	ldi		ZH, HIGH(MESSAGE*2)	; Ställer 
	ldi		ZL, LOW(MESSAGE*2)
	clr		r16

MAIN_LOOP:
	call GET_CHAR
	rjmp MAIN_LOOP



GET_CHAR:
	push	r16					; Sparar undan r16
NEXT_CHAR:
	lpm		r16, Z+
	cpi		r16, $00
	breq	ALL_CHARS_FETCHED
	call	SEND_CHAR
	rjmp	NEXT_CHAR
ALL_CHARS_FETCHED:
	pop		r16					; Skickar tillbaka r16
	ret

SEND_CHAR:
	
	ret




LONG_BEEP:
	ldi		r16, T
	push	r16
	call	BEEP
	ret

SHORT_BEEP:
	ldi		r16, T*2
	push	r16
	call	BEEP
	ret

BEEP:
	out		PORTB, r18
	ret





//---- Textmedelande ----
MESSAGE:
	.db "DATORTEKNIK", $00

BINARY_TABLE:
	.db $60, $88, $A8, $90, $40, $28, $D0, $08, $20, $78, $B0, $48, $E0, $A0, $F0, $68, $D8, $50, $10, $C0, $30, $18, $70, $98, $B8, $C8




