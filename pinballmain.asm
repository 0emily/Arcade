;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                            Pinbal Machine Main                             ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
; Revision History:
;    06/09/26      Emily Wu          initial revision
;    06/14/26      Emily Wu          revised comments

; chip definitions
.include  "m64def.inc"

; local include files
.include "timer.inc"                  ; delay timer symbol defs     

.include "2-sensors.inc"              ; sensor symbol definitions
.include "3-led.inc"                  ; LED symbol definitions
.include "4-sound.inc"                ; sound/actuator symbol defs
.include "pinball.inc"                ; game functionality symbol defs
.include "io.inc"                     ; input/output symbol defs


.cseg ;-------------------------------------------------------------------------

;setup the vector area

.org    $0000

        JMP     Start                   ;reset vector
        JMP     PC                      ;external interrupt 0
        JMP     PC                      ;external interrupt 1
        JMP     PC                      ;external interrupt 2
        JMP     PC                      ;external interrupt 3
        JMP     PC                      ;external interrupt 4
        JMP     PC                      ;external interrupt 5
        JMP     PC                      ;external interrupt 6
        JMP     PC                      ;external interrupt 7
        JMP     PC                      ;timer 2 compare match
        JMP     PC                      ;timer 2 overflow
        JMP     PC                      ;timer 1 capture
        JMP     PC                      ;timer 1 compare match A
        JMP     PC                      ;timer 1 compare match B
        JMP     PC                      ;timer 1 overflow
        ;JMP     PC                     ;timer 0 compare match
        JMP     Timer0CompareISR        ; replaced the above line
        JMP     PC                      ;timer 0 overflow
        JMP     PC                      ;SPI transfer complete
        JMP     PC                      ;UART 0 Rx complete
        JMP     PC                      ;UART 0 Tx empty
        JMP     PC                      ;UART 0 Tx complete
        JMP     PC                      ;ADC conversion complete
        JMP     PC                      ;EEPROM ready
        JMP     PC                      ;analog comparator
        JMP     PC                      ;timer 1 compare match C
        JMP     PC                      ;timer 3 capture
        JMP     PC                      ;timer 3 compare match A
        JMP     PC                      ;timer 3 compare match B
        JMP     PC                      ;timer 3 compare match C
        JMP     PC                      ;timer 3 overflow
        JMP     PC                      ;UART 1 Rx complete
        JMP     PC                      ;UART 1 Tx empty
        JMP     PC                      ;UART 1 Tx complete
        JMP     PC                      ;Two-wire serial interface
        JMP     PC                      ;store program memory ready

; start of the actual program

Start:                                  ;start the CPU after a reset
        LDI     R16, LOW(TopOfStack)    ;initialize the stack pointer
        OUT     SPL, R16
        LDI     R16, HIGH(TopOfStack)
        OUT     SPH, R16


        ;call initialization functions

        RCALL   InitTimer0              ; call timer0 initialization
        RCALL   InitTimer1              ; call timer1 initialization

        RCALL   InitPortsSensors        ; call port init, sensors [set 2]
        RCALL 	InitSensors 		; call sensor initialization

        RCALL   InitPortsLEDs        	; call port init, LEDs [set 3]
        RCALL   InitLEDMux              ; call LED Mux initialization

        RCALL   InitPortsSoundActuators ; call port init, sound/act [set 4]
        RCALL   InitActuator            ; call actuator initialization

        RCALL   InitSPI                 ; call SPI intialization
        RCALL   ClearDisplay            ; start by clearing all LED displays
        RCALL 	InitPinball             ; init pinball 

        SEI                             ; enable global interrupts

MainLoop:
		RCALL Main
		RJMP MainLoop


;the data segment --------------------------------------------------------------

.dseg

; buffer in which to store sensor activations (length must be 256)
SensorBuf:      .BYTE   256

; the stack - 128 bytes
                .BYTE   127
TopOfStack:     .BYTE   1               ;top of the stack

; buffer for data read from the EEROM
ReadBuffer:     .BYTE   128             ;EEROM is 1024 bits

; buffer containing the expected data from the EEROM
CompareBuffer:  .BYTE   128             ;EEROM is 1024 bits

; include all the .asm files ---------------------------------------------------
.include "pinball.asm"                  ; pinball helper functions/integration

.include "timer0ISR.asm"                ; timer 0 interrupt service routine
.include "timer.asm"                    ; delay timers 

.include "2-getHaveSensor.asm"          ; sensor routines & debouncing
.include "2-initSensors.asm"            ; timer and I/O port initialization

.include "4-set4DisplayLEDs.asm"        ; display hex digits & sensor array LEDs
.include "3-initLED.asm"                ; timer & port initialization

.include "4-initSound.asm"              ; timer, port, & actuator initialization 
.include "4-soundActuator.asm"          ; play notes, set actuators, RD/WR EEROM

.include "bin2bcd.asm"                  ; binary to bcd conversion
.include "div.asm"                      ; 24 bit division


