;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                       Initializations [LEDs]                               ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the functions for initializing the I/O ports and timer 
; for pinball machine LEDs. 
; The functions included are:
;    InitPorts   - initialize the I/O ports
;
; Revision History:
;    05/13/26  Emily Wu         initial revision
;    05/16/26  Emily Wu         removed an unecessary function (InitLEDs)
;    06/14/25  Emily Wu         revised for code quality

; code segment -----------------------------------------------------------------
.cseg


; Initialize I/O Ports ---------------------------------------------------------
; InitPortsLEDs--------------------------------------------------------------
; Description:       This procedure initializes the I/O ports for the LEDs. 
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
; Last Modified:     May 13, 2026 ----------------------------------------------- 

InitPortsLEDs:
        ; Port A outputs 
        LDI     R16, OUTDATA        ; set DDRA high s.t. all pins are output
        OUT     DDRA, R16

        LDI     R16, OUTDATA        ; set PORTA high 
        STS     PORTA, R16          ; since PORTA is active low, it is inactive

        ; Port C outputs 
        LDI     R16, OUTDATA        ; set DDRC high s.t. all pins are output
        OUT     DDRC, R16

        LDI     R16, OUTDATA        ; set PORTC high 
        STS     PORTC, R16          


        ; Port D outputs 
        LDI     R16, OUTDATA        ; set DDRD high s.t. all pins are output
        OUT     DDRD, R16

        LDI     R16, OUTDATA        ; set PORTD high 
        STS     PORTD, R16          

        RET
