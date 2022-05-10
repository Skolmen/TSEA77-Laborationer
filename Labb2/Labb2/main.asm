//---- Ställer in stackpekaren ----
SETUP:
	ldi			r16,HIGH(RAMEND)
	out			SPH, r16
	ldi			r16, LOW(RAMEND)
	out 		SPL, r16

	.equ 		SHORT = 10				
	.equ		LONG = SHORT * 3			
	.equ 		SPACE_WORDS = SHORT * 7		
	.equ 		FREQ = 500				; Vid 1 Mhz = 0,5 ms 370 i FREQ (Tror att det 1 MHz iallfall)
	ser			r16
	out			DDRB, r16
	clr			r16

//---- Ställer in Z - pekaren ----
START:
	ldi			ZH, HIGH(MESSAGE * 2)			; Ställer stack pekaren för textmeddelandet
	ldi			ZL, LOW (MESSAGE * 2)

MORSE:
	lpm			r16, Z+					; Hämtar bokstav från textsträngen
	cpi			r16, $00
	breq 		STRING_SENT					; Om texten har körts återställs Z-pekaren

	cpi			r16, $5b				; Om ASCII-värdet är större än $5A skickas ett mellanslag
	brcc 		IS_SPACE

	subi 		r16, $41
	brmi 		IS_SPACE				; Om flaggan N är satt är tecknet under ASCII-värder av A
	call 		LOOKUP					; Ändrar r16 till binärkodat

	call 		SEND_CHAR				; Sänd ut karaktären på r16

	rjmp 		MORSE
IS_SPACE:
	call 		SEND_SPACE
	rjmp 		MORSE
STRING_SENT:
	call		SEND_SPACE
	rjmp		START

//---- Översätter ASCII-tecknet till binärkodat ----
LOOKUP:
	push 		ZH 
	push 		ZL
	ldi			ZH, HIGH(BINARY_TABLE * 2)
	ldi			ZL, LOW (BINARY_TABLE * 2)
	add			ZL, r16
	;adc			ZH, ZERO
	lpm			r16, Z
	pop			ZL
	pop			ZH
	ret

//---- Sänder ut karaktären ------------------------
SEND_CHAR:
	cpi			r16, $80					; Om r16 har värdet $80 har tecknet skickats
	breq 		DONE_WITH_CHAR
	lsl			r16
	brcc 		SHORT_BEEP					; Om carry = 0 skicka en kort
	brcs 		LONG_BEEP					; Om carry = 1 skicka en lång
SHORT_BEEP:
	ldi			r21, SHORT					; 20 ms
	call 		SOUND
	rjmp 		BEEP_SENT
LONG_BEEP:
	ldi			r21, LONG					; 60 ms
	call 		SOUND
BEEP_SENT:
	ldi			r21, SHORT
	call 		NO_SOUND
	rjmp		SEND_CHAR
DONE_WITH_CHAR:
	ldi			r21, SHORT * 2
	call 		NO_SOUND
	ret

//---- Sänder ut mellanslag ------------------------
SEND_SPACE:
	cbi			PORTB, 7
	ldi			r21, SPACE_WORDS
	call 		NO_SOUND
	ret

//---- Ger ut ljudsignal ---------------------------
SOUND:
	sbi			PORTB, 7
	call 		WAIT
	cbi			PORTB, 7
	call 		WAIT					
	dec 		r21
	brne 		SOUND
	ret

//---- Tystnad -------------------------------------
NO_SOUND:
	cbi			PORTB, 7
	call 		WAIT
	call 		WAIT
	dec			r21
	brne 		NO_SOUND
	ret

//---- Väntan --------------------------------------
WAIT:
	push		r25
	push		r24
	//-----------------
	ldi 		r25, HIGH(FREQ)
	ldi 		r24, LOW(FREQ)
WAIT_INNER:
	sbiw  		r24, 1
	brne  		WAIT_INNER
	//-----------------
	pop			r24
	pop			r25
	ret

//---- Textmedelande ----
MESSAGE:
	.db "DATOR TEKNIK", $00
//---- Binary table ----
BINARY_TABLE:
	.db $60, $88, $A8, $90, $40, $28, $D0, $08, $20, $78, $B0, $48, $E0, $A0, $F0, $68, $D8, $50, $10, $C0, $30, $18, $70, $98, $B8, $C8
