;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                  Initializations [Sound/Actuators]                         ;
;                            Homework #4                                     ;
;                             EE/CS 10b                                      ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the functions for initializing the I/O ports and timer 
; for pinball machine LEDs. 
; The functions included are:
;    InitPorts   - initialize the I/O ports
;    InitTimer   - initialize timer 0 for interrupts
;
; Revision History:
;    05/13/26  Emily Wu         initial revision
;    05/26/26  Emily Wu         modified for HW 4
;    06/03/26  Emily Wu         updated comments
;    06/12/26  Emily Wu         Timer1 altered for PWM sound
;    06/14/25  Emily Wu         revised for code quality

; code segment -----------------------------------------------------------------
.cseg

; Initialize I/O Ports ---------------------------------------------------------
; InitPortsSoundActuators-------------------------------------------------------
; Description:       This procedure initializes the I/O ports for sound/the 
;                    actuators. 
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
; Last Modified:     May 26, 2026 ----------------------------------------------- 

InitPortsSoundActuators:
        ; Port B outputs 
        LDI     R16, OUTDATA        ; set DDRB high s.t. all pins are output
        OUT     DDRB, R16

        LDI     R16, OUTDATA        ; set PORTB high 
        STS     PORTB, R16          ; since PORTB is active low, it is inactive

        ; TPIC6273 Actuator Latch CLK setup
        SBI     DDRA, ACT_LATCH_CLK ; actuator latch clock = output 
        CBI     PORTA, ACT_LATCH_CLK; clock idle low

        RET


; Initialize Timer -------------------------------------------------------------
; InitTimer1--------------------------------------------------------------
; Description:       This procedure initializes timer1 for PWM sound. 
;
; Operation:         Timer 0 is setup for producing PWM sound. 
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  None.
;
; Input:             None.
; Output:            Timer 1 is initialized. 
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: flags, R16. 
;
; Author:            Emily Wu
; Last Modified:     May 12, 2026 -----------------------------------------------
InitTimer1:
        SBI     DDRB, SPEAKER_PIN

        ; Fast PWM Mode 14
        ; COM1A1=1 -> non-inverting PWM
        ; WGM11=1
        LDI     R16, (1<<COM1A1)|(1<<WGM11)
        OUT     TCCR1A, R16

        ; WGM13=1 WGM12=1
        ; Prescaler = clk/8
        LDI     R16, (1<<WGM13)|(1<<WGM12)|PRESCALE_BITS
        OUT     TCCR1B, R16

        CLR     R16

        OUT     ICR1H, R16
        OUT     ICR1L, R16

        OUT     OCR1AH, R16
        OUT     OCR1AL, R16

        RET

; InitActuator--------------------------------------------------------------
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
; Registers Changed: R16. 
;
; Author:            Emily Wu
; Last Modified:     May 13, 2026 -----------------------------------------------

InitActuator:     
        LDI     R16, BLANK          ; init currentActuators buffer as blank   
        STS     currentActuators, R16

        RET