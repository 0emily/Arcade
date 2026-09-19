;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                         Sensor Symbol Defs                                 ;
;                            Include File                                    ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the symbol definitions for the pinball machine I/O
;
; Revision History:
;    06/10/26  Emily Wu      	initial revision

; the data segment -------------------------------------------------------------

.dseg
; I/O port definitions ---------------------------------------------------------

.EQU	OUTDATA    = 0b11111111			  ; data direction 1 is output
.EQU    INDATA     = 0b00000000			  ; data direction 0 is input
