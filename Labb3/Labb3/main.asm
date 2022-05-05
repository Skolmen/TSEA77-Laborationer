
	.equ		DELAY = 25
	.equ		SEGMENTS = 4

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
	ldi			r16, HIGH(RAMEND)
	out			SPH, r16
	ldi			r16, LOW (RAMEND)
	out			SPL, r16

	ldi			r17, 0
	sts			CURRENT_SEGMENT, r17

	call		TIME_RESET

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
	rjmp		LOOP

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

	ldi			r16, 0				
	out			PORTB, r16

	lds			r17, CURRENT_SEGMENT

	ldi			XH, HIGH(TIME)
	ldi			XL, LOW (TIME)
	add			XL, r17

	ld			r16, X
	call		LOOKUP

	out			PORTA, r17
	call		WAIT
	out			PORTB, r16

	inc 		r17
	cpi			r17, SEGMENTS
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
	push		r17
	push		r18
	push		r19
	push		XH
	push		XL
	//----------------------

	ldi			XH, HIGH(TIME)
	ldi			XL, LOW (TIME)

	ldi			r17, SEGMENTS
	
BCD_INC:		
	clr			r16
	ld			r16, X
	inc			r16
	st 			X, r16

	mov			r19, r17
	lsr			r19
	brcc		ODD_NUM
EVEN_NUM:		//X0:X0
	ldi			r18, 6
	rjmp		BCD_COMP

ODD_NUM:		//0X:0X
	ldi			r18, 10

BCD_COMP:
	cp 			r16, r18
	brne		BCD_DONE
	clr			r16
	st			X+, r16
	dec			r17
	brne		BCD_INC

BCD_DONE:
	//----------------------
	pop			XL
	pop			XH
	pop			r19
	pop			r18
	pop			r17
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

WAIT:
	push		r25
	push		r24
	//-----------------
	ldi 		r25, HIGH(DELAY)
	ldi 		r24, LOW(DELAY)
WAIT_INNER:
	sbiw  		r24, 1
	brne  		WAIT_INNER
	//-----------------
	pop			r24
	pop			r25
	ret

TIME_RESET:
	push		XH
	push		XL
	push		r16
	push		r17
	//-----------------

	ldi			XH, HIGH(TIME)
	ldi			XL, LOW (TIME)

	ldi			r16, SEGMENTS
	ldi			r17, 0

FOR_EACH_TIME:
	st			X+, r17
	dec			r16
	cpi			r16, 0
	brne		FOR_EACH_TIME
	
	//-----------------			
	pop			r17
	pop			r16
	pop			XL
	pop			XH
	ret

SEG_DISP_TBL:
	.db $3F, $6, $5B, $4F, $66, $6D, $7D, $7, $7F, $67
	//  0,   1,  2,   3,   4,   5,   6,   7,  8,   9