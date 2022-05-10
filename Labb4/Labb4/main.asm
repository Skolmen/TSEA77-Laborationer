
	.equ	VMEM_SZ     = 5		; #rows on display
	.equ	AD_CHAN_X   = 3		; ADC0=PA0, PORTA bit 3 X-led
	.equ	AD_CHAN_Y   = 4		; ADC1=PA1, PORTA bit 4 Y-led
	.equ	GAME_SPEED  = 70	; inter-run delay (millisecs)
	.equ	PRESCALE    = 7		; AD-prescaler value
	.equ	BEEP_PITCH  = 20	; Victory beep pitch
	.equ	BEEP_LENGTH = 100	; Victory beep length
	
; ---------------------------------------
; --- Memory layout in SRAM
	.dseg
	.org	SRAM_START
POSX:	
	.byte	1	; Own position
POSY:	
	.byte 	1
TPOSX:	
	.byte	1	; Target position
TPOSY:	
	.byte	1
LINE:	
	.byte	1	; Current line	
VMEM:	
	.byte	VMEM_SZ ; Video MEMory
SEED:	
	.byte	1	; Seed for Random

; ---------------------------------------
; --- Macros for inc/dec-rementing
; --- a byte in SRAM
	.macro INCSRAM	; inc byte in SRAM
		lds	r16,@0
		inc	r16
		sts	@0,r16
	.endmacro

	.macro DECSRAM	; dec byte in SRAM
		lds	r16,@0
		dec	r16
		sts	@0,r16
	.endmacro

; ---------------------------------------
; --- Code
	.cseg
	.org 	$0
	jmp		START
	
	.org	INT0addr
	jmp		ISR0
	
	.org	INT_VECTORS_SIZE

START:
	// Ställer in stackpekare
	ldi		r16, HIGH(RAMEND)
	out		SPH, r16
	ldi		r17, LOW(RAMEND)
	out		SPL, r16

	ldi		r16, 3
	sts		SEED, r16


	call	AD_INIT
	call	IO_INIT
	call	HW_INIT	
	call	WARM
RUN:
	call	JOYSTICK
	call	ERASE_VMEM
	call	UPDATE

	;*** 	V�nta en stund s� inte spelet g�r f�r fort 	***
	
	;*** 	Avg�r om tr�ff				 	***

	brne	NO_HIT	
	ldi		r16, BEEP_LENGTH
	call	BEEP
	call	WARM
NO_HIT:
	jmp		RUN

; ---------------------------------------
; --- Interrupt 0
ISR0:	
	push	r16
	in		r16, SREG
	//----------------
	call	MUX
	INCSRAM SEED
	//----------------
	out		SREG, r16
	pop		r16
	reti
; ---------------------------------------
; --- Multiplex display
MUX:
	push	r16
	push	r17
	push	XH
	push	XL
	//------------------

	;*** 	skriv rutin som handhar multiplexningen och ***
	;*** 	utskriften till diodmatrisen. �ka SEED.		***

	ldi		r16, 0
	out		PORTB, r16

	lds		r17, LINE

	ldi		XH, HIGH(VMEM)
	ldi		XL, LOW(VMEM)
	add		XL, r17

	ld		r16, X

	out		PORTA, r17

	inc		r17
	cpi		r17, VMEM_SZ

	; call WAIT?
	;out		PORTB, r16

	brne	MUX_DONE
	clr		r17
	
MUX_DONE:
	sts		LINE, r17
	out		PORTB, r16
	//------------------
	pop		XL
	pop		XH
	pop		r17
	pop		r16
	ret

; ---------------------------------------
; --- JOYSTICK Sense stick and update POSX, POSY
; --- Uses r16
JOYSTICK:	
	push	r16

	;*** 	skriv kod som �kar eller minskar POSX beroende 	***
	;*** 	p� insignalen fr�n A/D-omvandlaren i X-led...	***

	;*** 	...och samma f�r Y-led 				***

	; Ta in data från joystick
	; PortA3 x-led = ADC 3 = 00011 ADMUX
	; PortA4 y-led = ADC 4 = 00100 ADMUX
	; Först X-led
	; Sedan y-led

	; X-LED
	ldi		r16, (1 << MUX0) | (1 << MUX1) //Ta in analogsignal på PORTA3 (X-led)
ADC_CONVERT:
	ldi		r17, (1<<ADEN) | (1 << ADPS1) | (1 << ADPS0) //AD-enable ställer in prescaler på 8
	out		ADCSRA, r17	//Laddar in r17
	out		ADMUX, r16	//Laddar in r16
CONVERT:
	sbi		ADCSRA, ADSC // Startar omvandling
WAIT_FOR_CONVERT:
	sbic	ADCSRA, ADSC // Väntar att omavandling ska bli klar
	rjmp	WAIT_FOR_CONVERT
	in		r16, ADCH

	; r16 = 0x40, 0x80 Ska stå stilla
	; r16 = 0xC0 (Upp/Vänster), 0x00 (Ner/Höger)
	; Minska eller öka X/Y-pos

	lds		r17, ADMUX
	cpi		r17, (1 << MUX2) | (1 << ADLAR) // Y-led
	breq	Y_DIR
X_DIR:
	cpi		r16, 0xC0
	breq	X_LEFT
	cpi		r16, 0
	breq	X_RIGHT
	rjmp	NEXT
X_LEFT:
	DECSRAM POSX
	rjmp NEXT
X_RIGHT:
	INCSRAM POSX
NEXT:
	ldi		r16, (1 << MUX2)
	rjmp	ADC_CONVERT	

Y_DIR:
	cpi		r16, 0xC0
	breq	Y_UP
	cpi		r16, 0
	breq	Y_DOWN
	rjmp	NEXT
Y_UP:
	INCSRAM POSY
	rjmp JOY_LIM
Y_DOWN:
	DECSRAM POSY

JOY_LIM:
	call	LIMITS		; don't fall off world!

	pop		r16
	ret

; ---------------------------------------
; --- LIMITS Limit POSX,POSY coordinates	
; --- Uses r16,r17
LIMITS:		//---- SKA EJ ÄNDRAS -----
	lds		r16,POSX	; variable
	ldi		r17,7		; upper limit+1
	call	POS_LIM		; actual work
	sts		POSX,r16
	lds		r16,POSY	; variable
	ldi		r17,5		; upper limit+1
	call	POS_LIM		; actual work
	sts		POSY,r16
	ret

POS_LIM:	//---- SKA EJ ÄNDRAS -----
	ori		r16,0		; negative?
	brmi	POS_LESS	; POSX neg => add 1
	cp		r16,r17		; past edge
	brne	POS_OK
	subi	r16,2
POS_LESS:
	inc	r16	
POS_OK:
	ret

; ---------------------------------------
; --- UPDATE VMEM
; --- with POSX/Y, TPOSX/Y
; --- Uses r16, r17
UPDATE:		//---- SKA EJ ÄNDRAS -----
	clr		ZH 
	ldi		ZL,LOW(POSX)
	call 	SETPOS
	clr		ZH
	ldi		ZL,LOW(TPOSX)
	call	SETPOS
	ret

; --- SETPOS Set bit pattern of r16 into *Z
; --- Uses r16, r17
; --- 1st call Z points to POSX at entry and POSY at exit
; --- 2nd call Z points to TPOSX at entry and TPOSY at exit
SETPOS:		//---- SKA EJ ÄNDRAS -----
	ld		r17,Z+  	; r17=POSX
	call	SETBIT		; r16=bitpattern for VMEM+POSY
	ld		r17,Z		; r17=POSY Z to POSY
	ldi		ZL,LOW(VMEM)
	add		ZL,r17		; *(VMEM+T/POSY) ZL=VMEM+0..4
	ld		r17,Z		; current line in VMEM
	or		r17,r16		; OR on place
	st		Z,r17		; put back into VMEM
	ret
	
; --- SETBIT Set bit r17 on r16
; --- Uses r16, r17
SETBIT:		//---- SKA EJ ÄNDRAS -----
	ldi		r16,$01		; bit to shift
SETBIT_LOOP:
	dec 	r17			
	brmi 	SETBIT_END	; til done
	lsl 	r16		; shift
	jmp 	SETBIT_LOOP
SETBIT_END:
	ret

; ---------------------------------------
; --- Hardware init
; --- Uses r16
HW_INIT:
	ldi			r16, (1<<ISC01) | (0<<ISC00)
	out			MCUCR, r16

	ldi			r16, (1<<INT0)
	out			GICR, r16
	
	sei			; display on
	ret

; ---------------------------------------
; --- I/O init
; --- Uses r16
IO_INIT:
	push	r16

	ser		r16
	out		DDRB, r16	//PB0-6 Disp, PB7, Ljud
	ldi		r16, $3
	out		DDRA, r16	//PA0-3 Disp row, PA3-4 joystick input
	
	pop		r16
	ret

; ---------------------------------------
; --- AD init
; --- Uses r16
AD_INIT:
	push	r16
	
	clr		r16
	ldi		r16, (1<<ADEN) | (1 << ADPS1) | (1 << ADPS0)
	out		ADCSRA, r16

	pop		r16
	ret
; ---------------------------------------
; --- WARM start. Set up a new game
WARM:
	push	r16
	push	r17

	;*** 	S�tt startposition (POSX,POSY)=(0,2)		***
	ldi		r16, 0
	sts		POSX, r16
	ldi		r16, 2
	sts		POSY, r16

	push	r0		
	push	r0		
	call	RANDOM		; RANDOM returns x,y on stack
	pop		r16
	pop		r17

	;*** 	S�tt startposition (TPOSX,POSY)				***
	sts		TPOSX, r16
	sts		TPOSY, r17

	call	ERASE_VMEM
	call	UPDATE

	pop		r17
	pop		r16
	ret

; ---------------------------------------
; --- RANDOM generate TPOSX, TPOSY  //KLAR?? Finns väl små fix med logiken och renare kod men annars fungerar det
; --- in variables passed on stack.
; --- Usage as:
; ---	push r0 
; ---	push r0 
; ---	call RANDOM
; ---	pop TPOSX 
; ---	pop TPOSY
; --- Uses r16
RANDOM:
	push	ZH
	push	ZL
	//---------------
	in  	ZH,SPH
	in  	ZL,SPL
	//---------------
	push	r16

	//Räknare ut posX
	lds		r16, SEED
	andi	r16, $7
	cpi		r16, 5
	brmi	NEXT_POS
	subi	r16, 4
NEXT_POS:
	std		Z + 5, r16
	sts		TPOSX, r16
	//Räknar ut POS_Y
	lds		r16, SEED
	andi	r16, $7
	std		Z + 6, r16
	sts		TPOSY, r16
	
	pop		r16
	pop		ZH
	pop		ZL
	ret


; ---------------------------------------
; --- Erase Videomemory bytes
; --- Clears VMEM..VMEM+4		//KLAR
ERASE_VMEM:
	push	XH
	push	XL
	push	r16
	push	r17
	//--------------
	
	ldi		XH, HIGH(VMEM)
	ldi		XL, LOW(VMEM)

	ldi		r16, VMEM_SZ
	ldi		r17, 0

FOR_EACH_VMEM:
	st		X+, r17
	dec		r16
	cpi		r16, 0
	brne	FOR_EACH_VMEM
	
	//--------------
	pop		r17
	pop		r16
	pop		XL
	pop		XH
	ret

; ---------------------------------------
; --- BEEP(r16) r16 half cycles of BEEP-PITCH //KLAR
BEEP:	
	sbi		PORTB,7
	call	BEEP_CYCLE
	cbi		PORTB, 7
	call	BEEP_CYCLE
	dec		r16
	brne	BEEP
	ret

BEEP_CYCLE:
	push		r25
	push		r24
	//-----------------
	ldi 		r25, HIGH(BEEP_PITCH)
	ldi 		r24, LOW(BEEP_PITCH)
BEEP_CYCLE_INNER:
	sbiw  		r24, 1
	brne  		BEEP_CYCLE_INNER
	//-----------------
	pop			r24
	pop			r25
	ret	