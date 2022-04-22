//---- St�ller in stackpekaren ----
SETUP:
	ldi		r16,HIGH(RAMEND)
	out		SPH, r16
	ldi		r16, LOW(RAMEND)
	out		SPL, r16

	.equ	SHORT = 20				
	.equ	LONG = SHORT * 3			
	.equ	SPACE_WORDS = SHORT * 7		
	.equ	FREQ = 125
	ser		r16
	out		DDRB, r16
	clr		r16

//---- St�ller in Z - pekaren ----
START:
	ldi		ZH, HIGH(MESSAGE * 2)	; St�ller stack pekaren f�r textmeddelandet
	ldi		ZL, LOW (MESSAGE * 2)

MORSE:
	lpm		r16, Z+					; H�mtar bokstav fr�n textstr�ngen
	cpi		r16, $00
	breq	START					; Om texten har k�rts �terst�lls Z-pekaren

	cpi		r16, $5b				; Om ASCII-v�rdet �r st�rre �n $5A skickas ett mellanslag
	brcc	IS_SPACE

	subi	r16, $41
	brmi	IS_SPACE				; Om flaggan N �r satt �r tecknet under ASCII-v�rder av A
	call	LOOKUP					; �ndrar r16 till bin�rkodat

	call	SEND_CHAR				; S�nd ut karakt�ren p� r16

	rjmp	MORSE
IS_SPACE:
	call	SEND_SPACE
	rjmp	MORSE

//---- �vers�tter ASCII-tecknet till bin�rkodat ----
LOOKUP:
	push	ZH 
	push	ZL
	ldi		ZH, HIGH(BINARY_TABLE * 2)
	ldi		ZL, LOW (BINARY_TABLE * 2)
	add		ZL, r16
	lpm		r16, Z
	pop		ZL
	pop		ZH
	ret

//---- S�nder ut karakt�ren ------------------------
SEND_CHAR:
	cpi		r16, $80					; Om r16 har v�rdet $80 har tecknet skickats
	breq	DONE_WITH_CHAR
	lsl		r16
	brcc	SHORT_BEEP					; Om carry = 0 skicka en kort
	brcs	LONG_BEEP					; Om carry = 1 skicka en l�ng
SHORT_BEEP:
	ldi		r21, SHORT					; 20 ms
	call	SOUND
	ldi		r21, SHORT
	call	NO_SOUND
	rjmp	SEND_CHAR
LONG_BEEP:
	ldi		r21, LONG					; 60 ms
	call	SOUND
	ldi		r21, SHORT
	call	NO_SOUND
	rjmp	SEND_CHAR
DONE_WITH_CHAR:
	ldi		r21, SHORT * 2
	call	NO_SOUND
	ret

//---- S�nder ut mellanslag ------------------------
SEND_SPACE:
	cbi		PORTB, 7
	ldi		r21, SPACE_WORDS
	call	NO_SOUND
	ret

//---- Ger ut ljudsignal ---------------------------
SOUND:
	sbi		PORTB, 7
	call	WAIT
	cbi		PORTB, 7
	call	WAIT					; Delay mellan beeps i bokstaven
	dec		r21
	brne	SOUND
	ret

NO_SOUND:
	cbi		PORTB, 7
	call	WAIT
	call	WAIT
	dec		r21
	brne	NO_SOUND
	ret

WAIT:
	ldi r25, HIGH(FREQ)
	ldi r24, LOW(FREQ)
WAIT_INNER:
	sbiw r24, 1
	brne WAIT_INNER
	ret

//---- Textmedelande ----
MESSAGE:
	.db "A,", $00
//---- Binary table ----
BINARY_TABLE:
	.db $60, $88, $A8, $90, $40, $28, $D0, $08, $20, $78, $B0, $48, $E0, $A0, $F0, $68, $D8, $50, $10, $C0, $30, $18, $70, $98, $B8, $C8