//---- St�ller in stackpekaren ----
SETUP:
	ldi		r16,HIGH(RAMEND)
	out		SPH, r16
	ldi		r16, LOW(RAMEND)
	out		SPL, r16

	.equ	SHORT = 30					; 20ms vid 1 MHz
	.equ	LONG = SHORT * 3			; 60ms vid 1 Mhz
	.equ	SPACE_WORDS = SHORT * 7		; 140ms vid 1 MHz
	.equ	DELAY_COUNT = 2
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
	rjmp	SEND_CHAR
LONG_BEEP:
	ldi		r21, LONG					; 60 ms
	call	SOUND
	rjmp	SEND_CHAR
DONE_WITH_CHAR:
	ldi		r21, SHORT * 2
	call	DELAY
	ret

//---- S�nder ut mellanslag ------------------------
SEND_SPACE:
	ldi		r21, SPACE_WORDS
	call	DELAY
	ret

//---- Ger ut ljudsignal ---------------------------
SOUND:
	sbi		PORTB, 7
	call	DELAY
	cbi		PORTB, 7
	ldi		r21, SHORT
	call	DELAY
	ret

//---- Delay, vid r21 = 30, 20ms ---------------------
DELAY:
	push	r20
	push	r19
	push	r18
	//-------------

	ldi		r19, DELAY_COUNT
	mov		r18, r21
DELAY_START:
	mov		r21, r18
DELAY_OUTER_LOOP:
	ldi		r20, $FF
DELAY_INNER_LOOP:
	dec		r20
	brne	DELAY_INNER_LOOP
	dec		r21
	brne	DELAY_OUTER_LOOP
	dec		r19
	brne	DELAY_START

	//-------------
	pop		r18
	pop		r19
	pop		r20
	ret

//---- Textmedelande ----
MESSAGE:
	.db "HEJ ", $00
//---- Binary table ----
BINARY_TABLE:
	.db $60, $88, $A8, $90, $40, $28, $D0, $08, $20, $78, $B0, $48, $E0, $A0, $F0, $68, $D8, $50, $10, $C0, $30, $18, $70, $98, $B8, $C8