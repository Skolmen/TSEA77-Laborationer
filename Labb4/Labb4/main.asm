
	.equ	VMEM_SZ     = 5		; #rows on display
	.equ	AD_CHAN_X   = 0		; ADC0=PA0, PORTA bit 0 X-led
	.equ	AD_CHAN_Y   = 1		; ADC1=PA1, PORTA bit 1 Y-led
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
	jmp		ISR0_MUX


START:
	// Ställer in stackpekare
	ldi		r16, HIGH(RAMEND)
	out		SPH, r16
	ldi		r17, LOW(RAMDEND)
	out		SPL, r16

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
; --- Multiplex display
ISR0_MUX:	
	push	r16
	push	r17
	push	XH
	push	XL
	//------------------

	;*** 	skriv rutin som handhar multiplexningen och ***
	;*** 	utskriften till diodmatrisen. �ka SEED.		***

	ldi		r16, 0
	out		PORTB, 0

	lds		r17, LINE

	ldi		XH, HIGH(VMEM)
	ldi		XL, LOW(VMEM)
	add		XL, r17

	ld		r16, X

	out		PORTA, r17
	; call WAIT?
	out		PORTB, r16

	inc		r17
	cpi		r17, VMEM_SZ
	brne	MUX_DONE
	clr		r17
	
MUX_DONE:
	sts		LINE, r17
	//------------------
	pop		XL
	pop		XH
	pop		r17
	pop		r16
	reti
		
; ---------------------------------------
; --- JOYSTICK Sense stick and update POSX, POSY
; --- Uses r16
JOYSTICK:	

	;*** 	skriv kod som �kar eller minskar POSX beroende 	***
	;*** 	p� insignalen fr�n A/D-omvandlaren i X-led...	***

	;*** 	...och samma f�r Y-led 				***

JOY_LIM:
	call	LIMITS		; don't fall off world!
	ret

; ---------------------------------------
; --- LIMITS Limit POSX,POSY coordinates	
; --- Uses r16,r17
LIMITS:
	lds		r16,POSX	; variable
	ldi		r17,7		; upper limit+1
	call	POS_LIM		; actual work
	sts		POSX,r16
	lds		r16,POSY	; variable
	ldi		r17,5		; upper limit+1
	call	POS_LIM		; actual work
	sts		POSY,r16
	ret

POS_LIM:
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
UPDATE:	
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
SETPOS:
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
SETBIT:
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

	;*** 	Konfigurera h�rdvara och MUX-avbrott enligt ***
	;*** 	ditt elektriska schema. Konfigurera 		***
	;*** 	flanktriggat avbrott p� INT0 (PD2).			***
	
	sei			; display on
	ret

; ---------------------------------------
; --- I/O init
; --- Uses r16
IO_INIT:
	ser		r16
	out		DDRB, r16
	ldi		r16, $7
	out		DDRA, r16
	ret

; ---------------------------------------
; --- WARM start. Set up a new game
WARM:

	;*** 	S�tt startposition (POSX,POSY)=(0,2)		***

	push	r0		
	push	r0		
	call	RANDOM		; RANDOM returns x,y on stack

	;*** 	S�tt startposition (TPOSX,POSY)				***

	call	ERASE_VMEM
	ret

; ---------------------------------------
; --- RANDOM generate TPOSX, TPOSY
; --- in variables passed on stack.
; --- Usage as:
; ---	push r0 
; ---	push r0 
; ---	call RANDOM
; ---	pop TPOSX 
; ---	pop TPOSY
; --- Uses r16
RANDOM:
	in		r16,SPH
	mov		ZH,r16
	in		r16,SPL
	mov		ZL,r16
	lds		r16,SEED
	
	;*** 	Anv�nd SEED f�r att ber�kna TPOSX		***
	;*** 	Anv�nd SEED f�r att ber�kna TPOSX		***

	;***		; store TPOSX	2..6
	;***		; store TPOSY   0..4
	ret


; ---------------------------------------
; --- Erase Videomemory bytes
; --- Clears VMEM..VMEM+4
	
ERASE_VMEM:

;*** 	Radera videominnet						***

	ret

; ---------------------------------------
; --- BEEP(r16) r16 half cycles of BEEP-PITCH
BEEP:	

	;*** skriv kod f�r ett ljud som ska markera tr�ff 	***

	ret

			