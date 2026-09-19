;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                           LED Symbol Defs                                  ;
;                            Include File                                    ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the symbol definitions for the pinball machine LED
; procedures.
;
; Revision History:
;    05/13/26  Emily Wu      	initial revision
; 	 05/16/26  Emily Wu		   	updated comments


; the data segment -------------------------------------------------------------

.dseg
.equ	LED_BLANK 	= 0b00000000 			; pattern for clearing all LEDs
.equ 	MUX_DISABLE = 0b00011000			; G (enable)=active low, so set high
.equ 	DIG_OFFSET1 = 7 					; offset for LEDs 4 and 5
.equ 	DIG_OFFSET2 = 23					; offset for LEDs 6 and 7 (23=15+7)

.equ 	INIT_MASK 	= 0b00000001 			; init row mask to update LED array

.equ 	FULL_DIM 	= 16 					; 16 rows of LEDs & 16 digits
.equ	DIMENSION 	= 8 					; each row is 8 LEDs
.equ	MOD_FACTOR 	= DIMENSION - 1 		; used for X % DIMENSION

; DisplayHex -------------------------------------------------------------------
.equ 	PLAYER_MIN  	= 	1 				; game requires at least 1 player
.equ 	PLAYER_TOO_HIGH = 	5 				; game cannot support >=5 players
.equ 	NUM_HEX_DIGS 	= 	4 				; each hex display has 4 digits
.equ 	NIBBLE_SIZE 	= 	4 				; for shifting thru digits
.equ 	NIBBLE_MASK 	= 	0b00001111 		; mask for the low nibble

; DisplayLights ----------------------------------------------------------------
.equ 	LIGHT_MIN  		= 	0 				; the lowest light number is 0
.equ 	LIGHT_TOO_HIGH 	= 	128 			; light numbers >=128 are not viable
.equ 	NO_COLS 		= 	0 				; all columns exhausted
;.equ 	OFF 			= 	0 				; s=0 is off, s=1 is on
