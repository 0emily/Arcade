;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                     Timer0 Interrupt Handler                               ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the interrupt handler for timer0.
; Revision History:
;    06/09/26  Emily Wu         Initial revision

.cseg 

; Timer0CompareISR -------------------------------------------------------------
; Description:       This function is ISR/interrupt service routine for timer0. 
;
; Operation:         When timer0 reaches a compare, the function executes. The
;                    the registers are saved and ScanDebounce, MuxLEDs, and
;                    TimerHandler are called. 
;                    The timer counter is preloaded to ensure a consistent 
;                    interrupt. All registers are restored after returning.
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: R16
;
; Author:            Emily Wu
; Last Modified:     June 9, 2026 ----------------------------------------------

Timer0CompareISR:
    PUSH R0                 
    in R0, SREG             ; save status register
    PUSH R0

    PUSH    R16             ; save registers
    PUSH    R17
    PUSH    R18
    PUSH    R19
    PUSH    R20
    PUSH    R21
    PUSH    R22

    PUSH    YL
    PUSH    YH

    PUSH    ZL
    PUSH    ZH

    LDI R16, TCNT0_PRELOAD  ; preload timer counter
    out TCNT0, R16          ; allow timer to cont. counting from preloaded val
    NOP

    RCALL   ScanDebounce
    RCALL   MuxLEDs
    RCALL   TimerHandler

    POP     ZH
    POP     ZL

    POP     YH
    POP     YL

    POP     R22             ; restore registers
    POP     R21
    POP     R20
    POP     R19
    POP     R18
    POP     R17
    POP     R16

    POP     R0
    OUT     SREG, R0        ; restore status register
    POP     R0

    RETI


