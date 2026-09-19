;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                          Sensor Functions                                  ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains functions pertinent to sensor activation, checking for
; sensor availability, and the process of scanning/debouncing. 
; The functions included are:
;       InitSensors  -  Initializes sensor variables. 
;       GetSensor    -  returns a debounced sensor activation from sensor array
;       HaveSensor   -  returns TRUE if debounced sensor activation is available
;       ScanDebounce -  checks for new sensors or debounces active sensors
;
; Revision History:
;    04/30/26  Emily Wu         initial revision (used ChatGPT free model)
;    05/01/26  Emily Wu         fixed GetSensor() (added blocking functionality)
;    05/02/26  Emily Wu         Prevented autorepeat; addressed critical code;
;                               ensured functionality on board; moved keyValue 
;                               translation to foreground (GetSensor)
;    05/03/26  Emily Wu         added comments
;    06/09/26  Emily Wu         removed timer0ISR (relocated to own file)
;    06/14/25  Emily Wu         revised for code quality


; code segment -----------------------------------------------------------------
.cseg

; Initialize Sensor Variables --------------------------------------------------
; InitSensors-------------------------------------------------------------------
; Description:       This procedure initializes the sensor variables.  
;
; Operation:         The downFlag, row counter, debounce counter, and col count-
;                    -er shared variables are initialized. 
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  downFlag - flag: sensor is debounced & activated [WR]
;                    debounceCounter - num interrupts since sensor 1st pressed [WR]
;                    currCol - column of currently pressed sensor [WR]
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
; Last Modified:     May 3, 2026 -----------------------------------------------
InitSensors:

    ; downFlag = FALSE              ; indicates when there is a debounced 
    LDI     R16, FALSE_VALUE        ;   & activated switch.
    STS     downFlag, R16

    ; row                           ;  used for iterating thru sensor array rows 
    LDI     R16, ROWCOL_INIT
    STS     row, R16

    ; debounceCounter               ; counts num timer interrupts since a switch 
    LDI     R16, DEBOUNCE_INIT      ;   was first pressed to execute debouncing
    STS     debounceCounter, R16

    ; currCol = 0                   ; column of the currently pressed sensor
    LDI     R16, 0
    STS     currCol, R16

    RET

; HaveSensor -------------------------------------------------------------------
; Description:       This function returns a value of true if a debounced sensor
;                    activation is available. If HaveSensor returns with the 
;                    zero flag reset, GetSensor would return immediately if 
;                    called because there is a debounced sensor activation 
;                    available. 
;
; Operation:         This function returns true if a debounced activated sensor
;                    is available. The inverse of downFlag sets zeroFlag. 
;
; Arguments:         None.
; Return Value:      Zero flag reset if debounced sensor activation available
;                    Zero flag set otherwise. 
;
; Local Variables:   None.
; Shared Variables:  downFlag - indicates when there is a debounced activated 
;                    switch (RD). 
;
; Input:             Sensor activation.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: Z (ZH | ZL) 
;
; Author:            Emily Wu
; Last Modified:     May 2, 2026 -----------------------------------------------


HaveSensor:
    PUSH    R16

    LDS     R16, downFlag   ; indicates if debounced activated sensor is avail.
    TST     R16             ; Z=1 if zero (no sensor), Z=0 otherwise

    POP     R16

    RET

; GetSensor --------------------------------------------------------------------
; Description:       Returns a debounced sensor activation from the sensor array   
;
; Operation:         If HaveSensor is false, GetSensor remains in a busy wait.
;                    Otherwise, when HaveSensor is true: if downFlag is true, 
;                    then the sensor code (keyValue) will be stored in register  
;                    R16. Then, downFlag will be set to false regardless of its 
;                    original state, because storing the key value has concluded
;                    the operation of the switch for this particular activation.    
;
; Arguments:         None.
; Return Value:      Returns with the code for the debounced sensor activation 
;                    from the sensor array in register R16 (KeyValue). 
;                    The range of values and their corresponding switch are 
;                    indicated below:
;    +--------+--------+--------+--------+--------+--------+--------+--------+
;    |SW34=17 |SW35=16 |SW36=15 |SW37=14 |SW38=13 |SW39=12 |SW40=11 |SW41=10 |
;    +--------+--------+--------+--------+--------+--------+--------+--------+
;    |SW26=27 |SW27=26 |SW28=25 |SW29=24 |SW30=23 |SW31=22 |SW32=21 |SW33=20 |
;    +--------+--------+--------+--------+--------+--------+--------+--------+
;    |SW18=47 |SW19=46 |SW20=45 |SW21=44 |SW22=43 |SW23=42 |SW24=41 |SW25=40 |
;    +--------+--------+--------+--------+--------+--------+--------+--------+
;    |SW10=87 |SW11=86 |SW12=85 |SW13=84 |SW14=83 |SW15=82 |SW16=81 |SW17=80 |
;    +--------+--------+--------+--------+--------+--------+--------+--------+
;    |SW2=07  |SW3=06  |SW4=05  |SW5=04  |SW6=03  |SW7=02  |SW8=01  |SW9=00  |
;    +--------+--------+--------+--------+--------+--------+--------+--------+
;
; Local Variables:   None.
; Shared Variables:  downFlag - indicates when there is a debounced activated 
;                    switch (RD/WR). 
;                    keyValue - represents the code for each sensor (RD). 
;                    latchedCol - stores current column for keyValue (RD)
;                    latchedRow - stores current row for keyValue (RD). 
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: Flags, R0, R16, R17, R19, R22
;
; Author:            Emily Wu
; Last Modified:     May 2, 2026 -----------------------------------------------


GetSensor:

GS_Wait:
    ; busy wait loop 
    RCALL  HaveSensor     ; sets Z flag if there's no debounced activated sensor
    BREQ   GS_Wait        ; loop while no sensor is available
    ;BRNE  GS_Continue
GS_Continue:
    ; critical code - cannot interrupt
    IN R0, SREG           ; save interrupt flag status
    NOP
    CLI                   ; can't interrupt this code
    
    ; get keyValue for current sensor
    ; high nibble of keyValue = low nibble of currRow
    LDS     R22, latchedRow
    ANDI    R22, LOW_NIBBLE
    SWAP    R22           ; move to upper nibble

    ; low nibble of keyValue = low nibble of currCol
    LDS     R19, latchedCol
    ANDI    R19, LOW_NIBBLE
    OR      R22, R19      ; combine row and column nibbles to get full keyValue

    ; since sensor is available, we return keyValue
    MOV    R16, R22

    ; set downFlag to FALSE regardless of original state
    LDI    R17, FALSE_VALUE
    STS    downFlag, R17

    OUT    SREG, R0        ; restore flags, possibly renabling interrupt
    NOP

    RET

; ScanDebounce -----------------------------------------------------------------
; Description:       This function returns a debounced sensor activation from 
;                    the sensor array. The function is called with no arguments.
;                    It returns with specified codes/keys associated with each 
;                    of the sensors for the debounced sensor activation from the
;                    sensor array in R16. These codes are only returned after a 
;                    given sensor is both activated and debounced, though not 
;                    necessarily deactivated. 
;
; Operation:         downFlag is inspected to determine if the function should 
;                    exit to prevent auto-repeating. If there is no currently
;                    activated sensor, the current row is scanned, with necessa-
;                    -ary modifications performed because pins are active low. 
;                    Columns are read from pinE and the original input is stored
;                    for later comparison. If no column is low, the debounce
;                    counter is reset and the next row is scanned. If a sensor
;                    has potentially been pressed, then the function begins
;                    debouncing. If the same sensor has been pressed for the 
;                    threshold time, the signal is considered an activated and 
;                    debounced sensor. The sensor index and row are stored for 
;                    the foreground code to construct keyValue. 
;                    The downFlag is set. 
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  downFlag - flag: sensor is debounced & activated (RD/WR)
;                    debounceCounter - # interrupts since sensor 1st pressed (RD/WR)
;                    latchedRow - stores current row for keyValue (WR)
;                    latchedCol - stores current column for keyValue (WR)
;
; Input:             sensor values from pinE and current debounce state.
; Output:            PORTG signals.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: R16, R17, R18, R19, R20, R21
;
; Author:            Emily Wu
; Last Modified:     May 2, 2026 -----------------------------------------------   

ScanDebounce:
    LDS R16, downFlag           
    TST R16                      ; Z is set if downFlag is low
    BREQ skip                    ; if Z set, keep scanning
    ;BRNE SD_Done
SD_Done:
    RJMP SD_End                  ; if Z not set, go to end and return

skip:
    ; scan row
    LDS     R16, row             ; get current row 
    COM     R16                  ; invert row bits such that active is low
    ANDI    R16, ROW_MASK        ; apply mask to only get the 5 bits for PORTG
    STS     PORTG, R16           ; output to PORTG
    NOP                          ; unecessary for simulator; required for board

    ; read columns
    IN      R17, PINE            ; read columns
    MOV     R21, R17             ; save original read input
    STS     currRow, R17         ;  and store it   

    CPI     R17, NO_PRESS        ; if all bits are high, nothing is pressed
    BRNE    SD_CheckDebounce     ; low bits indicate a press (start debouncing)
    ;BREQ   SD_NoInput

; nothing pressed --------------------------------------------------------------
SD_NoInput:
    LDI     R20, 0               ; load zero
    STS     debounceCounter, R20 ; debounceCounter reset if no sensor pressed

    ; shift the row to get bit in correct position
    LDS     R16, row             ; get current row
    LSL     R16                  ; left shift row
    BRNE    row_ok               ; if not wrapped to the end, proceed
    ;BREQ   row_reset
row_reset:
    LDI     R16, ROW_WRAP_VALUE  ; if wrapped over the end, go back to row 0
row_ok:
    STS     row, R16             ; save new row

    RJMP    SD_End               ; go to end and return

; debouncing -------------------------------------------------------------------
SD_CheckDebounce:

    ; compare with previous sensor processed
    LDS     R18, previousRow     ; get saved original input
    CP      R18, R21             ; compare with current sensor
    BRNE    SD_ResetDebounce     ; if not equal, reset debounceCounter
    ;BREQ   SD_DebounceCtrInc
SD_DebounceCtrInc:
    ; if same sensor, increment debounceCounter
    LDS     R20, debounceCounter ; get current debounceCounter
    INC     R20                  ; increment to proceed with debouncing
    STS     debounceCounter, R20

    CPI     R20, DEBOUNCE_THRESH ; compare debounceCounter with threshold
    BRLO    SD_SaveAndExit       ; when below threshold, continue debouncing

    BRNE    SD_ThreshReached     ; when above threshold, stop incrementing  

; debounce confirmed -----------------------------------------------------------

    MOV     R20, R21             ; get sensor input
    CLR     R19                  ; set column index to zero

SD_ColLoop:
    MOV     R17, R20
    ANDI    R17, ROWCOL_INIT     ; inspect last bit
    BREQ    SD_ColFound          ; when last bit 0, col identified
    ;BRNE   SD_ColContinue
SD_ColContinue:
    LSR     R20                  ; test next bit by right-shifting
    INC     R19                  ; increment column
    CPI     R19, ROW_LEN
    BRLO    SD_ColLoop           ; continue through all bits
    ;BRSH   SD_ColDone
SD_ColDone:
    RJMP    SD_End               ; end when no valid column

SD_ColFound:
    STS     currCol, R19         ; get column under current inspection
 
    ; latch values
    STS     latchedCol, R19      ; latch this column (to use for keyValue)
    LDS     R16, row             ; load row
    STS     latchedRow, R16      ; latch this row (to use for keyValue)

    LDI     R18, DEBOUNCED_TRUE               
    STS     downFlag, R18        ; set downFlag to indicate debounced/activated

    RJMP    SD_SaveAndExit       ; end and return

SD_ThreshReached:
    DEC     R20                  ; stop incremnting debounceCounter after thresh
    STS     debounceCounter, R20
    RJMP    SD_SaveAndExit

; new press --------------------------------------------------------------------
SD_ResetDebounce:
    LDI     R20, 0               ; reset debounceCounter if sensor released
    STS     debounceCounter, R20

SD_SaveAndExit:
    STS     previousRow, R21     ; store current row for next iteration

SD_End:
    RET                          ; return 

; the data segment -------------------------------------------------------------

.dseg
row:                .byte 1     ; for iterating through sensor array rows
currRow:            .byte 1     ; 8-bit bus with the current values in port E
currCol:            .byte 1     ; column of currently pressed sensor
debounceCounter:    .byte 1     ; num interrupts since sensor was first pressed
downFlag:           .byte 1     ; when a sensor is debounced AND activated

latchedRow:         .byte 1     ; stores current row for keyValue
latchedCol:         .byte 1     ; stores current column for keyValue

previousRow:        .byte 1     ; row from previous scanning iteration  
