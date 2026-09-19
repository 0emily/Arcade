;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                          Initializations                                   ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the functions for initializing the I/O ports, timer, and 
; variables for the pinball machine sensors. 
; The functions included are:
;    InitPorts   - initialize the I/O ports
;    InitTimer   - initialize timer 0 for interrupts
;    InitSensors - initialize sensor variables
;
; Revision History:
;    04/30/26  Emily Wu         initial revision
;    05/03/26  Emily Wu         added comments
;    06/14/25  Emily Wu         revised for code quality

; code segment -----------------------------------------------------------------
.cseg


; Initialize I/O Ports ---------------------------------------------------------
; InitPortsSensors--------------------------------------------------------------
; Description:       This procedure initializes the I/O ports for the sensors. 
;
; Operation:         The direction bits and ports are set appropriately. 
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  None.
;
; Input:             None.
; Output:            The I/O ports are initialized. 
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: flags, R16. 
;
; Author:            Emily Wu
; Last Modified:     May 3, 2026 -----------------------------------------------

InitPortsSensors:
        ; Port G outputs (scanning rows)
        LDI     R16, OUTDATA        ; set DDRG high s.t. all pins are output
        STS     DDRG, R16

        LDI     R16, OUTDATA        ; set PORTG high 
        STS     PORTG, R16          ; since PORTG is active low, it is inactive

        ; Port E inputs (reading columns)
        LDI     R16, INDATA         ; set DDRE low s.t. all pins are input
        STS     DDRE, R16

        LDI     R16, OUTDATA        ; set PORTE high so it is also inactive
        STS     PORTE, R16

        RET

; Initialize Timer -------------------------------------------------------------
; InitTimer0--------------------------------------------------------------
; Description:       This procedure initializes timer0 for approx 1 ms interrupts
;
; Operation:         Timer 0 is setup for approx 1 ms interrupts. 
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  None.
;
; Input:             None.
; Output:            Timer 0 is initialized. 
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: flags, R16. 
;
; Author:            Emily Wu
; Last Modified:     May 3, 2026 -----------------------------------------------

InitTimer0:

    ; set clear timer on compare mode (CTC): TCNT increases until matching OCR 
    LDI     R16, TIMER0_WGM01       ; variable w/ CTC mode
    OUT     TCCR0, R16              ;   is stored in timer/counter ctrl register

    ; set output compare register (OCR)
    LDI     R16, TIMER0_COMPARE     ; compare value for desired clk period
    OUT     OCR0, R16               ; when TCNT0 = OCR0, a compare will occur

    ; enable OCR interrupt for comparison
    IN      R16, TIMSK              ; timer interrupt mask register - saves
    NOP                             ;   pre-existing interrupt enable bits
    ORI     R16, TIMER0_OCIE0       
    OUT     TIMSK, R16
    NOP

    ; start timer
    LDI     R16, TIMER0_WGM01 | TIMER0_PRESCALE ; prescale sets clk division
    OUT     TCCR0, R16              ; timer starts incrementing

    SEI                             ; enable global interrupt
    RET

