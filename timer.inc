;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   timer.inc                                ;
;                          Timing Routines Include File                      ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the definitions for the timing functions defined in
; timer.asm and the setup values for timer0. 
;
; Revision History:
;     9/30/13  Glen George      initial revision
;     4/30/18  Glen George      updated comments
; 	  6/10/26  Emily Wu			added setup values for timer0. 




;delay timer constants
.EQU	TIMER_CNT = 8			;number of delay timers

; setup values for Timer 0 -----------------------------------------------------
.EQU    TIMERCLK32   = 0b00000011		  ; timer runs at CLK/32

.EQU    TIMER0_WGM01     = 0b00001000     ; set waveform generation mode to CTC
.EQU    TIMER0_OCIE0     = 0b00000010     ; compare match interrupt enable

; Timer 0 configuration for 1 ms interrupt (8 MHz CPU, prescaler 64)
.EQU    TIMER0_PRESCALE  = TIMERCLK32
.EQU    TIMER0_COMPARE   = 124
.EQU	TCNT0_PRELOAD    = 131			  ; 255 minus TIMER0_COMPARE