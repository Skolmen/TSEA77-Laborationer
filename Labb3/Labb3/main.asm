//--- Avbrottskod ---------------------
	.org		$0000
	jmp			INIT

	.org		INT0addr
	jmp			INTERRUPT_INT0

	.org		INT1addr
	jmp			INTERRUPT_INT1

	.org		INT_VECTORS_SIZE

//--- Initiering ----------------------
INIT:
	ldi			r16, HIGH(RAMEND)
	out			SPH, r16
	ldi			r16, LOW (RAMEND)
	out			SPL, r16

INIT_INTERUPTS:
	ldi			r16, (1<<ISC01) | (0<<ISC00) | (1<<ISC11) | (0<<ISC10)
	out			MCUCR,r16

	ldi			r16, (1<<INT0) | (1<<INT1)
	out			GICR, r16

	sei

LOOP:
	jmp LOOP

//--- Avbrottsrutiner -------------------------
INTERRUPT_INT0:
	push		r16
	in			r16,SREG
	push		r16
	; H�r ska n�got g�ras men vad �r fr�gan???
	; 
	pop			r16
	out			SREG, r16
	pop			r16
	reti

INTERRUPT_INT1:
	push		r16
	in			r16,SREG
	push		r16
	; H�r ska n�got g�ras men vad �r fr�gan???
	; 
	pop			r16
	out			SREG, r16
	pop			r16
	reti

//---- Datasegment f�r TIME --------------------
.dseg
TIME: .byte 4 ; Definerar TIME