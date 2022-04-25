.dseg
.org $60

TIME: .byte 4 ; Definerar TIME


.cseg
	ldi		r16, $41
	sts		TIME, r16
	ldi		r17, TIME + 1

