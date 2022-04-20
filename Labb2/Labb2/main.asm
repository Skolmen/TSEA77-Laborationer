//---- St�ller in stackpekaren ----
SETUP:
	ldi		r16,HIGH(RAMEND)
	out		SPH, r16
	ldi		r16, LOW(RAMEND)
	out		SPL, r16

	.equ	SHORT = 50
	.equ	LONG = SHORT * 3
	.equ	SPACE_WORDS = SHORT * 7
	ser		r16
	out		DDRB, r16
	clr		r16

//---- St�ller in Z - pekaren ----
START:
	ldi		ZH, HIGH(MESSAGE * 2)	; St�ller stack pekaren f�r textmeddelandet
	ldi		ZL, LOW (MESSAGE * 2)

MORSE:
	call	GET_CHAR
	breq	START					; Om texten har k�rts �terst�lls Z-pekaren
	subi	r16, $41
	brmi	IS_SPACE				; Om flaggan N �r satt �r tecknet ett minus
	call	LOOKUP					; �ndrar r16 till bin�rkodat
	call	SEND_CHAR				; S�nd ut karakt�ren p� r16
	rjmp	MORSE
IS_SPACE:
	call	SEND_SPACE
	rjmp	MORSE

//---- H�mtar karakt�r fr�n textmedelande ----------
GET_CHAR:
	lpm		r16, Z+
	cpi		r16, $00
	ret

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
	; Skicka en kort beep
	rjmp	SEND_CHAR
LONG_BEEP:
	; Skicka en kort beep
	rjmp	SEND_CHAR
DONE_WITH_CHAR:
	call	WAIT		; V�nta 3 beep
	ret

//---- S�nder ut mellanslag ------------------------
SEND_SPACE:
	call	WAIT		; V�nta 7 beep
	ret

WAIT:
	
	; V�nta antalet som beh�vs
	
	ret

SOUND:
	
	; Skicka ut en signal p� PORTB

	ret

//Vet inte hur delayen riktigt ska fungera �nnu
DELAY:
	ldi		r20, $1F
DELAY_INNER_LOOP:
	dec		r20
	brne	DELAY_INNER_LOOP
	dec		r21
	brne	DELAY
	ret


//---- Textmedelande ----
MESSAGE:
	.db "TEKNIK", $00
//---- Binary table ----
BINARY_TABLE:
	.db $60, $88, $A8, $90, $40, $28, $D0, $08, $20, $78, $B0, $48, $E0, $A0, $F0, $68, $D8, $50, $10, $C0, $30, $18, $70, $98, $B8, $C8