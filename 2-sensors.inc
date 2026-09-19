;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                         Sensor Symbol Defs                                 ;
;                            Include File                                    ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the symbol definitions for the pinball machine sensor
; procedures.
;
; Revision History:
;    04/30/26  Emily Wu      	initial revision
;    05/02/26  Emily Wu      	added new variables
;    05/03/26  Emily Wu         added comments
; 	 06/14/25  Emily Wu 		revised for code quality

; Scanning/Debouncing ----------------------------------------------------------
.equ ROW_MASK        = 0b00011111      ; mask for PortG, which has 5 bits
.equ ROW_WRAP_VALUE  = 0b00000001      ; [0,0,0,0,0,0,0,1]
.equ ROWCOL_INIT     = 0b1 			   ; for initial row/column
.equ LOW_NIBBLE		 = 0b1111 		   ; used for making keyValue
.equ NO_PRESS 	     = 0b11111111 	   ; no sensors pressed (all bits high)

.equ FALSE_VALUE     = 0b0
.equ ZERO_VALUE      = 0

.equ DEBOUNCE_THRESH = 10              ; [ms] sensor debounced if held this long
.equ DEBOUNCE_INIT   = DEBOUNCE_THRESH ; starts debounceCounter at threshold
.equ DEBOUNCED_TRUE  = 1 			   ; downFlag when a sensor is debounced
.equ ROW_LEN 		 = 8 			   ; length of a row
