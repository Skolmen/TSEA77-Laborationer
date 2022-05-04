//---- Datasegment i SRAM -------------
	.dseg
	.org		0x0060
ARR:
TIME: 
	.byte 4		; Definerar TIME
CURRENT_SEGMENT:
	.byte 1

//--- Kodsegment i FLASH --------------
	.cseg

	.org		$0000
	jmp			INIT

	.org		INT0addr
	jmp			ISR0

	.org		INT1addr
	jmp			ISR1

	.org		INT_VECTORS_SIZE

//--- Initiering ----------------------
INIT:
	ldi			r16, HIGH(RAMEND)
	out			SPH, r16
	ldi			r16, LOW (RAMEND)
	out			SPL, r16

	ldi			r17, 0
	sts			CURRENT_SEGMENT, r17

INIT_IO:
	ldi			r16, $7F
	out			DDRB, r16
	ldi			r16, $2
	out			DDRA, r16

INIT_INTERUPTS:
	ldi			r16, (1<<ISC01) | (0<<ISC00) | (1<<ISC11) | (0<<ISC10)
	out			MCUCR, r16

	ldi			r16, (1<<INT0) | (1<<INT1)
	out			GICR, r16

	sei

LOOP:
	call		BCD
	jmp			LOOP

//--- Avbrottsrutiner -------------------------
ISR0:
	push		r16
	in			r16,SREG
	//----------------------
	call		BCD
	//----------------------
	out			SREG, r16
	pop			r16
	reti

ISR1:
	push		r16				//Sparar undan register som kommer användas i rutinen
	in			r16,SREG		//Sparar undan statusregistret
	//----------------------
	call		MUX
	//----------------------
	pop			r16
	out			SREG, r16
	reti
//-----------------------------------------------

MUX:
	push		r16
	push		r17
	push		XH
	push		XL
	//----------------------

	; Hämta nuvarnade segment
	; Hämta siffra från TIME
	; Lägg in på register
	; Gå in i lookup
	; Skicka ut innehållet på look up till portb
	; gör detta 4 gånger
	; profit?

	lds			r17, CURRENT_SEGMENT

	ldi			XH, HIGH(TIME)
	ldi			XL, LOW (TIME)

	ld			r16, X
	call		LOOKUP

	out			PORTA, r17
	out			PORTB, r16

	inc 		r17
	add			XL, r17
	cpi			r17, 4
	brne		MUX_DONE
	clr			r17

MUX_DONE:
	sts			CURRENT_SEGMENT, r17

	//----------------------
	pop			XL
	pop			XH
	pop			r17
	pop			r16
	ret

BCD:
	push		r16
	push		XH
	push		XL
	//----------------------

	ldi			XH, HIGH(TIME)
	ldi			XL, LOW (TIME)

	; 00:0X
	clr			r16
	ld			r16, X
	inc			r16
	st 			X, r16
	cpi			r16, 10
	brne		BCD_DONE
	clr			r16
	st			X+, r16

	; 00:X0
	clr			r16
	ld			r16, X
	inc			r16
	st 			X, r16
	cpi			r16, 6
	brne		BCD_DONE
	clr			r16
	st			X+, r16

	; 0X:00
	clr			r16
	ld			r16, X
	inc			r16
	st 			X, r16
	cpi			r16, 10
	brne		BCD_DONE
	clr			r16
	st			X+, r16

	; X0:00
	clr			r16
	ld			r16, X
	inc			r16
	st 			X, r16
	cpi			r16, 10
	brne		BCD_DONE
	clr			r16
	st			X+, r16


BCD_DONE:
	//----------------------
	pop			XL
	pop			XH
	pop			r16
	ret


LOOKUP:
	push 		ZH 
	push 		ZL
	ldi			ZH, HIGH(SEG_DISP_TBL * 2)
	ldi			ZL, LOW (SEG_DISP_TBL * 2)
	add			ZL, r16
	lpm			r16, Z
	pop			ZL
	pop			ZH
	ret

SEG_DISP_TBL:
	.db $3F, $6, $5B, $4F, $64, $6D, $7D, $7, $7F, $67
	//  0,   1,  2,   3,   4,   5,   6,   7,  8,   9