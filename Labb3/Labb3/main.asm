//---- Datasegment i SRAM -------------
	.dseg
	.org		SRAM_START
TIME: 
	.byte 4		; Definerar TIME

//--- Kodsegment i FLASH --------------
	.cseg

	.org		$0000
	jmp			INIT

	.org		INT0addr
	jmp			BCD_INT0

	.org		INT1addr
	jmp			INTERRUPT_INT1

	.org		INT_VECTORS_SIZE

//--- Initiering ----------------------
INIT:
	ldi			r16, 0b01100011
	out			PORTB, r16

	ldi			r16, HIGH(RAMEND)
	out			SPH, r16
	ldi			r16, LOW (RAMEND)
	out			SPL, r16

	ldi			r16, 5
	sts			TIME, r16
	ldi			r16, 6
	sts			TIME + 1, r16
	ldi			r16, 7
	sts			TIME + 2, r16
	ldi			r16, 8
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
BCD_INT0:
	push		r16
	in			r16,SREG
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
	out			SREG, r16
	pop			r16
	reti

INTERRUPT_INT1:
	push		r16				//Sparar undan register som kommer användas i rutinen
	push		r17
	push		ZH
	push		ZL
	in			r16,SREG		//Sparar undan statusregistret
	push		r16				//------""-------
	//----------------------

	; hämta siffra från TIME
	; Lägg in på register
	; Gå in i lookup
	; Skicka ut innehållet på look up till portb
	; gör detta 4 gånger
	; profit?

	ldi			r17, 0
	ldi			ZH, HIGH(TIME)
	ldi			ZL, LOW (TIME)
DISP_LOOP:
	ld			r16, Z+
	call		LOOKUP
	out			PORTA, r17
	out			PORTB, r16
	inc 		r17
	cpi			r17, 4
	brne		DISP_LOOP

	//----------------------
	pop			r16
	out			SREG, r16
	pop			ZL
	pop			ZH
	pop			r17
	pop			r16
	reti

LOOKUP:
	push 		ZH 
	push 		ZL
	ldi			ZH, HIGH(SEG_DISP_TBL * 2)
	ldi			ZL, LOW (SEG_DISP_TBL * 2)
	adiw		Z, r16
	lpm			r16, Z
	pop			ZL
	pop			ZH
	ret

SEG_DISP_TBL:
	.db $3F, $6, $5B, $4F, $64, $6D, $7D, $7, $7F, $67
	//  0,   1,  2,   3,   4,   5,   6,   7,  8,   9