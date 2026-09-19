;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                           LED Functions                                    ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains functions pertinent to LED displays, 
; The functions included are:
;       Timer0CompareISR() - interrupt service routine for timer0. 
;       ClearDisplay()     - clears all LEDs
;       DisplayHex(n, p)   - outputs the number n on the LED for player p in hex
;       DisplayLight(l, s) - sets lth light to the state s (true on, false off)
;       MuxLEDs()          - determines which row or digit to update
;       InitLEDMux()       - initializes buffer index variable used by the mux
;
;
; Revision History:
;    05/13/26  Emily Wu         Initial revision 
;    05/14/26  Emily Wu         Implemented error handling in DisplayHex/Light.
;    05/15/26  Emily Wu         Fixed light array mask & shifting. 
;    05/16/26  Emily Wu         PUSH/POP Y and Z registers, updated comments,
;                               combined dig/row index variable, & fixed mapping 
;                               btwn rows and digits.
;    05/30/26  Emily Wu         Updated MuxLEDs to mux actuator lights (set 4).
;    06/02/26  Emily Wu         Updated registers PUSHed/POPped.
;    06/03/26  Emily Wu         Updated comments.
;    06/14/25  Emily Wu         revised for code quality

; code segment -----------------------------------------------------------------
.cseg

; ClearDisplay() ---------------------------------------------------------------
; Description:       Clears the display such that all LEDs are off. 
;
; Operation:         The function clears all of the LEDs in the display. 
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  currentRows   - buffer holding current displayed row 
;                                    patterns (RD/WR)
;                    currentDigits - buffer with current displayed 7seg patterns
;                                    (RD/WR)
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: Z (ZH | ZL), Y (YH | YL), R16, R17
;
; 
; Author:            Emily Wu
; Last Modified:     May 13, 2026 ----------------------------------------------

ClearDisplay:

    LDI     YL, LOW(currentRows)            ; load the row buffer
    LDI     YH, HIGH(currentRows)

    LDI     ZL, LOW(currentDigits)          ; load the digit buffer
    LDI     ZH, HIGH(currentDigits)

    LDI     R17, FULL_DIM                   ; get the number of rows and digits
    LDI     R16, LED_BLANK                  ; get the blank state for an LED

ClearDisplayLoop:

    ST      Y+, R16                         ; blank each row in currentRows
    ST      Z+, R16                         ; blank each digit in currentDigits

    DEC     R17                             ; proceed to the next row, digit                 
    BRNE    ClearDisplayLoop

    RET


; DisplayHex(n,p) --------------------------------------------------------------
; Description:       Outputs the number n to the 7-segment LED display for 
;                    player p in hexadecimal. 
;
; Operation:         The function is passed a 16-bit unsigned value to output 
;                    (n) in hexadecimal (at most 4 digits) to the 7-segment LED 
;                    display for the passed player number (p). n is split into 
;                    its four nibbles. The number (n) is
;                    passed in R17|R16 by value. The player number (p) is 
;                    between 1 and 4 and is passed by value in R18.
;                    The provided  table DigitSegTable is used to translate
;                    the hex number to the correct segment pattern. 
;
; Arguments:         n: a 16-bit unsigned hexadecimal value with at most 4 
;                       digits (R17|R16).
;                    p: player number between 1 and 4 (R18).
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  currentDigits - buffer with current displayed 7seg patterns
;                                    (RD/WR). 
;
; Input:             None.
; Output:            Displays digits on the hex display(s).
;
; Error Handling:    Return if player number is not between 1 and 4 (inclusive). 
;
; Algorithms:        Table lookup.
; Data Structures:   A table of segment patterns. 
;
; Registers Changed: R0, R19, R20, R21, R22, R23, R24, R25, Y (YH | YL), 
;                    Z (ZH | ZL)
;
; Author:            Emily Wu
; Last Modified:     May 13, 2026 ----------------------------------------------

DisplayHex:

    CPI     R18, PLAYER_MIN                ; error handle: p<min => return        
    BRLO    DisplayHexDone
    CPI     R18, PLAYER_TOO_HIGH           ; error handle: p>=max+1 => return
    BRSH    DisplayHexDone 

    DEC     R18                            ; p = (p-1)*4
    MOV     R19, R18                       ; p becomes index for desired digit
    LSL     R19                 
    LSL     R19

    LDI     YL, LOW(currentDigits)         ; load the digit buffer
    LDI     YH, HIGH(currentDigits)

    CLR     R0
    ADD     YL, R19                        ; get to buffer row w/ the digit
    ADC     YH, R0

    MOV     R20, R16                       ; copy low byte of n
    MOV     R21, R17                       ; copy high byte of n

    LDI     R22, NUM_HEX_DIGS              ; we will loop for the num of digits


DisplayHexLoop:

    MOV     R23, R20                       
    ANDI    R23, NIBBLE_MASK               ; get lowest current nibble (digit)

    LDI     ZL, LOW(DigitSegTable * 2)     ; get the start of the table
    LDI     ZH, HIGH(DigitSegTable * 2)
    EOR     R0, R0                         ; zero R0 for carry propagation
    ADD     ZL, R23                        ; add in the table offset
    ADC     ZH, R0

    LPM     R24, Z                         ; get the segment pattern
    ST      Y+, R24                        ; update the buffer with the seg patt

    LDI     R25, NIBBLE_SIZE               ; shifting will be by nibble


ShiftNibbleLoop:

    LSR     R21                            ; shift to gradually get next digit
    ROR     R20

    DEC     R25                            ; update counter
    BRNE    ShiftNibbleLoop
    ;BREQ   DH_NextDig
DH_NextDig:
    DEC     R22                            ; once a full nibble has been shifted
    BRNE    DisplayHexLoop                 ; can get pattern for the next digit

DisplayHexDone:

    RET

; DisplayLight(l, s) -----------------------------------------------------------
; Description:       Sets the lth light to the passed state s with TRUE for on 
;                    and FALSE for off. 
;
; Operation:         The function is passed a 7-bit light number (l) in R16 
;                    that indicates the pinball machine light to turn on or off.
;                    It is translated to the correct row and column through 
;                    integer division by 8 (-> row) and the resulting remainder
;                    from that division (-> col). 
;                    The new state of the light (s) is passed by value in R17. 
;                    The corresponding pinball machine light is turned on if the
;                    passed state is TRUE (non-zero) and turned off if the 
;                    passed state is FALSE (zero). This is done using a mask. 
;
; Arguments:         l: 7-bit light number indicating which pinball machine 
;                       light turns on or off (R16). 
;                    s: new state of the light (TRUE/FALSE). The pinball machine
;                        light turns on if s is true, and turns off if it is 
;                        FALSE (R17). 
; Return Value:      None.
;
; Local Variables:   None.  
; Shared Variables:  currentRows - buffer holds current displayed row patterns 
;                                  (RD/WR).
;
; Input:             None.
; Output:            Activates LEDs in the LED array.
;
; Error Handling:    Return if light number isn't between 0 and 127 (inclusive). 
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: R0, R16, R20, R21, R22, Z (ZH | ZL). 
;
; Special Notes:     The number one and the light number look similar. 
;                    Side-by-side for reference: 1 (one), l (light number)
;
; Author:            Emily Wu
; Last Modified:     May 13, 2026 ----------------------------------------------

DisplayLight:

    CPI     R16, LIGHT_MIN                 ; error handle: l<0 => return
    BRLO    DisplayLightDone     
    CPI     R16, LIGHT_TOO_HIGH            ; error handle: l>=128 => return
    BRSH    DisplayLightDone


ComputeRowCol:

    MOV     R20, R16                       ; row = l//8
    LSR     R20                            
    LSR     R20
    LSR     R20 

    ANDI    R16, MOD_FACTOR                ; col = l % 8

    LDI     ZL, LOW(currentRows)           ; load currentRow buffer into Z
    LDI     ZH, HIGH(currentRows)

    CLR     R0
    ADD     ZL, R20                        ; go to the calculated row in buffer
    ADC     ZH, R0

    LD      R21, Z                         ; load current pattern for that row

    LDI     R22, INIT_MASK                 ; build mask, starting from initial 


MaskShift:

    CPI     R16, NO_COLS                   ; if shifted same number of times as     
    BREQ    MaskDone                       ; the column, the mask is complete
    ;BRNE   DL_ShiftContinue
DL_ShiftContinue:
    LSL     R22                            ; otherwise, keep shifting
    DEC     R16
    RJMP    MaskShift

MaskDone:

    CPI     R17, OFF                       ; determine the state of s (on/off)
    BRNE    LightOn
    ;BREQ   LightOff
LightOff:

    COM     R22                            ; if s off, invert the mask first
    AND     R21, R22                       ; then the LED is ensured to be off
    RJMP    Store

LightOn:

    OR      R21, R22                       ; if s on, LED is ensured to be on

Store:

    ST      Z, R21                         ; update buffer with new pattern 

DisplayLightDone:

    RET

; MuxLEDs() -----------------------------------------------------------------
; Description:       Multiplexes the LEDs under interrupt control. Called by 
;                    the timer event handler. It is called at a regular interval
;                    of about 1 ms. Also handles actuators. 
;
; Operation:         This procedure outputs the next row and digit (from the
;                    currentRows and currentDigits buffers respectively) to the 
;                    memory mapped LEDs each time it is called. To do this
;                    it outputs the segments/columns that should have the
;                    row/digit on, respectively. The row/digit to output are
;                    determined by curMuxRow or curMuxDigit
;                    respectively, which are also updated by
;                    by this function. One row and/or digit is output every time
;                    the function is called.
; 
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  currentRows - buffer holds current displayed row patts (RD)
;                    curMuxIndex - current row/digit number muxed (RD/WR)
;                    currentDigits - buffer w/ current displayed 7seg patts (RD)
;
; Input:             None.
; Output:            outputs LEDs, actuators, and displays using multiplexing. 
;
; Error Handling:    None.
;
; Algorithms:        Table lookup.
; Data Structures:   A table of values for PortA & another for actuator patterns 
;
; Registers Changed: Z (ZH | ZL), Y (YH | YL), R0, R16, R17, R18, R20, R21, R22, 
;                    R23
;
; Author:            Emily Wu
; Last Modified:     June 2, 2026 ----------------------------------------------


MuxLEDs:
    
    LDI     R16, MUX_DISABLE              ; disable both muxes
    OUT     PORTA, R16
    CLR     R16                           ; blank the outputs
    OUT     PORTC, R16
    OUT     PORTD, R16
    ; v new code from set 4 v---------------------------------------------------
    LDS     R22, ActuatorFlag             ; check if actuator update is needed
    TST     R22
    BREQ    SkipActuatorUpdate            ; if not, skip all actuator code
    ;BRNE   Actuator_Continue
ActuatorContinue:
    LPM     R21, Z                        ; get normal mux pattern
    ORI     R21, MUX_DISABLE              ; force G enables high (turn LEDs off)
    OUT     PORTA, R21

    LDS     R22, currentActuators         ; load buffer with actuator statuses

    LDI     ZL, LOW(ActuatorPortDTable * 2)     ; get the start of the table
    LDI     ZH, HIGH(ActuatorPortDTable * 2)

    EOR     R0, R0                              ; zero R0 for carry propagation
    ADD     ZL, R22                             ; add in the table offset
    ADC     ZH, R0

    LPM     R22, Z                              ; get the actuator pattern
    OUT     PORTD, R22                          ; output to port D

    SBI     PORTA, ACT_LATCH_CLK                ; pulse the latch clock 
    NOP
    NOP
    NOP
    NOP
    CBI     PORTA, ACT_LATCH_CLK                ; finish pulse

    CLR     R22                         
    STS     ActuatorFlag, R22                   ; clear update flag 
    ; ^ new code from set 4 ^---------------------------------------------------

SkipActuatorUpdate:
    CLR     R0

    LDS     R17, curMuxIndex            ; get current digit/row index
    MOV     R22, R17                    ; store a copy of the index. 

    CPI     R22, DIMENSION              ; we'll augment the mapping btwn the
    BRLO    LowerHalf                   ;   array rows and the hex digits. 
    ;BRSH   UpperHalf
    UpperHalf:                          ; if the digit is in LED 6 or 7,
        LDI     R23, DIG_OFFSET2        ; we should update the digit that is at
        SUB     R23, R22                ; DIG_OFFSET2 - index
        RJMP    DigitIndexDone

    LowerHalf:                          ; if the digit is in LED 4 or 5, 
        LDI     R23, DIG_OFFSET1        ; we should update the digit that is at
        SUB     R23, R22                ; DIG_OFFSET1 - index.

    DigitIndexDone:

        LDI     YL, LOW(currentDigits)  ; load the digit buffer
        LDI     YH, HIGH(currentDigits)

        ADD     YL, R23                 ; go to the augmented digit index. 
        ADC     YH, R0

        LD      R18, Y                     


    LDI     ZL, LOW(currentRows)        ; load the row buffer
    LDI     ZH, HIGH(currentRows)

    ADD     ZL, R17                     ; go to the row index (not augmented)
    ADC     ZH, R0

    LD      R20, Z

    OUT     PORTC, R18                  ; set PORTC = CurrentDigits[aug_index]
    OUT     PORTD, R20                  ; set PORTD = CurrentRows[curMuxIndex]


    LDI     ZL, LOW(MuxSelectTable * 2) ; get the start of the PortA table.
    LDI     ZH, HIGH(MuxSelectTable * 2)
    EOR     R0, R0                      ;zero R0 for carry propagation
    ADD     ZL, R17                     ; add in the table offset
    ADC     ZH, R0 

    LPM     R21, Z                      ; get the appropriate PortA pattern
    OUT     PORTA, R21                  ; output the pattern to PortA


OutputPortA:
    OUT     PORTA, R21
    INC     R17                         ; increment curMuxIndex

    CPI     R17, FULL_DIM               ; check if we're at the end of buffer
    BRLO    NoWrap

    CLR     R17

NoWrap:
    STS     curMuxIndex, R17

    RET


; InitLEDMux() -----------------------------------------------------------------
; Description:       This procedure initializes the variables used by the code
;                    that multiplexes the LED display.
;
; Operation:         The row and digit number to be multiplexed next is reset.
; 
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  curMuxIndex - current row num being multiplexed (start @ 0)
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: R16.
;
; Author:            Emily Wu
; Last Modified:     May 16, 2026 ----------------------------------------------

InitLEDMux:
    CLR     R16

    STS     curMuxIndex, R16           ; reset the digit/row index

    RET

; MuxSelectTable ---------------------------------------------------------------
;
; Description:      This is the multiplexer select table. It contains the corre-
;                   -spondence between the multiplexer drain pins and the 
;                   microcontroller PORTA outputs to determine the currently
;                   selected row (in the array) or digit (in the hex displays). 
;
; Author:           Emily Wu
; Notes:            Used ChatGPT (Free Model)
; Last Modified:    May 13, 2026 -----------------------------------------------
MuxSelectTable:

; Mux U4 active (LED9, LED6/LED7)
;        PORTA76543210   PORTA76543210
    .DB     0b00001111,     0b00001110
    .DB     0b00001101,     0b00001100
    .DB     0b00001011,     0b00001010
    .DB     0b00001001,     0b00001000


; Mux U5 active (LED8, LED4/LED5)
;        PORTA76543210   PORTA76543210
    .DB     0b00010111,     0b00010110
    .DB     0b00010101,     0b00010100
    .DB     0b00010011,     0b00010010
    .DB     0b00010001,     0b00010000

; DigitSegTable ----------------------------------------------------------------
;
; Description:      This is the segment pattern table for hexadecimal digits.
;                   It contains the active-high segment patterns for all hex
;                   digits (0123456789AbCdEF).  None of the codes set the
;                   decimal point.  
;
; Notes:            READ ONLY tables should always be in the code segment so
;                   that in a standalone system it will be located in the
;                   ROM with the code.
;
; Author:           Glen George
; Last Modified:    May 18, 2024 -----------------------------------------------

DigitSegTable:


;        DB       gfeedcba    gfeedcba   ; Hex Digit

        .DB     0b01111111, 0b00000110   ; 0, 1
        .DB     0b10111011, 0b10001111   ; 2, 3
        .DB     0b11000110, 0b11001101   ; 4, 5
        .DB     0b11111101, 0b00000111   ; 6, 7
        .DB     0b11111111, 0b11000111   ; 8, 9
        .DB     0b11110111, 0b11111100   ; A, b
        .DB     0b01111001, 0b10111110   ; C, d
        .DB     0b11111001, 0b11110001   ; E, F


; ActuatorPortDTable -----------------------------------------------------------
;
; Description:      This is the actuator pattern select table. It contains the
;                   correspondence between TPIC6273 drain pins that feed to the 
;                   actuator LED array and the microcontroller PORTD outputs.
;                   The mapping between the microntroller pins and the TPIC6273
;                   drains is: 
;                   PD0/SCL/INT0  ->  D4
;                   PD1/SDA/INT1  ->  D5
;                   PD2/RXD1/INT2 ->  D3
;                   PD3/TXD1/INT3 ->  D6
;                   PD4/ICP1      ->  D2
;                   PD5/XCK1      ->  D7
;                   PD6/T1        ->  D1
;                   PD7/T2        ->  D8
;
; Author:           Emily Wu
; Notes:            Used ChatGPT
; Last Modified:    May 30, 2026 -----------------------------------------------

ActuatorPortDTable:
.DB 0x00, 0x40, 0x10, 0x50, 0x04, 0x44, 0x14, 0x54 
.DB 0x01, 0x41, 0x11, 0x51, 0x05, 0x45, 0x15, 0x55
.DB 0x02, 0x42, 0x12, 0x52, 0x06, 0x46, 0x16, 0x56 
.DB 0x03, 0x43, 0x13, 0x53, 0x07, 0x47, 0x17, 0x57
.DB 0x08, 0x48, 0x18, 0x58, 0x0C, 0x4C, 0x1C, 0x5C
.DB 0x09, 0x49, 0x19, 0x59, 0x0D, 0x4D, 0x1D, 0x5D
.DB 0x0A, 0x4A, 0x1A, 0x5A, 0x0E, 0x4E, 0x1E, 0x5E
.DB 0x0B, 0x4B, 0x1B, 0x5B, 0x0F, 0x4F, 0x1F, 0x5F
.DB 0x20, 0x60, 0x30, 0x70, 0x24, 0x64, 0x34, 0x74
.DB 0x21, 0x61, 0x31, 0x71, 0x25, 0x65, 0x35, 0x75
.DB 0x22, 0x62, 0x32, 0x72, 0x26, 0x66, 0x36, 0x76
.DB 0x23, 0x63, 0x33, 0x73, 0x27, 0x67, 0x37, 0x77
.DB 0x28, 0x68, 0x38, 0x78, 0x2C, 0x6C, 0x3C, 0x7C
.DB 0x29, 0x69, 0x39, 0x79, 0x2D, 0x6D, 0x3D, 0x7D
.DB 0x2A, 0x6A, 0x3A, 0x7A, 0x2E, 0x6E, 0x3E, 0x7E
.DB 0x2B, 0x6B, 0x3B, 0x7B, 0x2F, 0x6F, 0x3F, 0x7F
.DB 0x80, 0xC0, 0x90, 0xD0, 0x84, 0xC4, 0x94, 0xD4
.DB 0x81, 0xC1, 0x91, 0xD1, 0x85, 0xC5, 0x95, 0xD5
.DB 0x82, 0xC2, 0x92, 0xD2, 0x86, 0xC6, 0x96, 0xD6
.DB 0x83, 0xC3, 0x93, 0xD3, 0x87, 0xC7, 0x97, 0xD7
.DB 0x88, 0xC8, 0x98, 0xD8, 0x8C, 0xCC, 0x9C, 0xDC
.DB 0x89, 0xC9, 0x99, 0xD9, 0x8D, 0xCD, 0x9D, 0xDD
.DB 0x8A, 0xCA, 0x9A, 0xDA, 0x8E, 0xCE, 0x9E, 0xDE
.DB 0x8B, 0xCB, 0x9B, 0xDB, 0x8F, 0xCF, 0x9F, 0xDF
.DB 0xA0, 0xE0, 0xB0, 0xF0, 0xA4, 0xE4, 0xB4, 0xF4
.DB 0xA1, 0xE1, 0xB1, 0xF1, 0xA5, 0xE5, 0xB5, 0xF5
.DB 0xA2, 0xE2, 0xB2, 0xF2, 0xA6, 0xE6, 0xB6, 0xF6
.DB 0xA3, 0xE3, 0xB3, 0xF3, 0xA7, 0xE7, 0xB7, 0xF7
.DB 0xA8, 0xE8, 0xB8, 0xF8, 0xAC, 0xEC, 0xBC, 0xFC
.DB 0xA9, 0xE9, 0xB9, 0xF9, 0xAD, 0xED, 0xBD, 0xFD
.DB 0xAA, 0xEA, 0xBA, 0xFA, 0xAE, 0xEE, 0xBE, 0xFE
.DB 0xAB, 0xEB, 0xBB, 0xFB, 0xAF, 0xEF, 0xBF, 0xFF


; data segment -----------------------------------------------------------------
.dseg

curMuxIndex:     .BYTE  1           ; current digit/row number being multiplexed

; sensor array display
currentRows:    .BYTE   FULL_DIM    ; buffer holds current displayed row patts

; 7-segment displays
currentDigits:   .BYTE  FULL_DIM    ; buffer holds current displayed 7seg patts

