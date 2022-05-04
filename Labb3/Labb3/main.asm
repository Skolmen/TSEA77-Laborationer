//---- Datasegment i SRAM -------------
	.dseg
	.org		SRAM_START
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
	ldi			r16, 0b01100011
	out			PORTB, r16

	ldi			r16, HIGH(RAMEND)
	out			SPH, r16
	ldi			r16, LOW (RAMEND)
	out			SPL, r16

	ldi			r17, 0
	sts			CURRENT_SEGMENT, r17

	ldi			r16, 7
	sts			TIME, r16
	ldi			r16, 3
	sts			TIME + 1, r16
	ldi			r16, 3
	sts			TIME + 2, r16
	ldi			r16, 1
	sts			TIME + 3, r16

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
	jmp LOOP

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

	ld			r16, Z
	call		LOOKUP

	out			PORTB, r16
	out			PORTA, r17

	inc 		r17
	add			ZL, r17
	cpi			r17, 4
	brne		LAST_SEGMENT
	clr			r17

LAST_SEGMENT:
	sts			CURRENT_SEGMENT, r17


	//----------------------
	pop			XL
	pop			XH
	pop			r17
	pop			r16
	ret

BCD:
	push		r16
	//----------------------

TIME_0:									; 00:0X
	lds			r16, TIME
	cpi			r16, $9
	breq		TIME_1
	inc			r16
	sts			TIME, r16
	jmp			COUNT_DONE
TIME_1:									; 00:X0
	lds			r16, $0
	sts			TIME, r16

	lds			r16, TIME + 1
	cpi			r16, $5
	breq		TIME_2
	inc			r16
	sts			TIME + 1, r16
	jmp			COUNT_DONE
TIME_2:
	lds			r16, $0
	sts			TIME + 1, r16

	lds			r16, TIME + 2
	cpi			r16, $9
	breq		TIME_3
	inc			r16
	sts			TIME + 1, r16
	jmp			COUNT_DONE
TIME_3:
	lds			r16, $0
	sts			TIME + 2, r16

	lds			r16, TIME + 3
	cpi			r16, $5
	breq		RESET
	inc			r16
	sts			TIME + 3, r16
	jmp			COUNT_DONE

RESET:
	ldi			r16, $00
	sts			TIME, r16
	sts			TIME + 1, r16
	sts			TIME + 2, r16
	sts			TIME + 3, r16


COUNT_DONE:
	//----------------------
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