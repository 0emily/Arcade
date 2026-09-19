;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                     Sound/Actuator Functions                               ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains functions pertinent to LED displays, 
; The functions included are:
;    PlayNote(f)        - plays a note with frequency f from the speaker
;    Div24()            - performs 24 bit by 24 bit division
;    SetActuator(a, s)  - updates the actuator, a, with the state s (on/off)
;    ReadEEROM(a, p, n) - reads the n bytes of the EEROM at address a and stores
;                             data at address p. 
;    ReadWord(a)        - reads a single word at address a. 
;    WriteEEROM(a, p, n)- writes n bytes of the EEROM at address a using data 
;                             stored at address p. 
;    WriteWord(a)       - writes a single word at address a. 
;    InitSPI()          - initializes the SPCR, SPSR, and DDRB. 
;    SPI_TxRx()         - loop that waits until the SPI interrupt flag is set
;
; Revision History:
;    05/26/26  Emily Wu         Initial revision.
;    05/29/26  Emily Wu         Adapted division function Div24 from Div16. 
;    05/30/26  Emily Wu         Fixed PlayNote and SetActuators.
;    06/02/26  Emily Wu         Fixed EEROM-related functions. 
;    06/03/26  Emily Wu         Updated comments. 
;    06/12/26  Emily Wu         Changed to PWM sound
;    06/14/26  Emily Wu         Revised file for code quality

; code segment -----------------------------------------------------------------
.cseg

; PlayNote(f) ------------------------------------------------------------------
; Description:       The function plays the note with the passed frequency (f, 
;                    in Hz) on the speaker. This tone is output until a new tone 
;                    is output via this function. A frequency of 0 Hz (passed
;                    value is 0) turns off the speaker output. The frequency (f) 
;                    is a 16-bit value passed by value in R17 | R16 (R17 is the 
;                    high byte).
;
; Operation:         If f=0 then the speaker is turned off. Otherwi-
;                    -se, N is calculated (N is also OCR1A). The speaker settin-
;                    -gs are then configured for COM1A, the waveform generation
;                    mode, and the clock prescaler. 
;
; Arguments:         f: frequency in Hz. [special value: f=0 turns speaker off]
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  None.
;
; Input:             None.
; Output:            Sound is played from the speakers. 
;
; Error Handling:    If f = 0 then the speaker is turned off. 
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: R16, R17, R18, R19, R20, R21.
; 
; Author:            Emily Wu
; Last Modified:     06/03/26 --------------------------------------------------

PlayNote:
        TST     R16                      ; f != 0, then proceed to normal play
        BRNE    PlayTone
        TST     R17
        BRNE    PlayTone
        ;BREQ   TurnOffSpeaker

TurnOffSpeaker:                          ; f == 0, then just output the 0 freq
        OUT     OCR1AH, R16              ;      to OCR1A  
        OUT     OCR1AL, R16
        RJMP    SoundDone                ; and finish

PlayTone:
        MOV     R19, R16                 ; divisor = frequency
        MOV     R20, R17
        CLR     R21

        LDI     R16, LOW(FREQ_FACTOR)     ; load in frequency factor bytes
        LDI     R17, HIGH(FREQ_FACTOR)
        LDI     R18, BYTE3(FREQ_FACTOR)

        RCALL   Div24                   ; perform 24 bit division

        SUBI    R16, 1                  ; subtract 1 for toggle after 0
        SBCI    R17, 0

        OUT     ICR1H, R17              ; set ICR1
        OUT     ICR1L, R16

        MOV     R18, R17
        MOV     R19, R16
        LSR     R18
        ROR     R19

        OUT     OCR1AH, R18             ; OCR1A = ICR1 / 2
        OUT     OCR1AL, R19
SoundDone:
        RET

; Div24 ------------------------------------------------------------------------
; Description:       This function divides the 24-bit unsigned value passed in
;                    R18|R17|R16 by the 24-bit unsigned value passed in 
;                    R21|R20|R19.
;                    The quotient is returned in R18|R17|R16 and the remainder 
;                    is returned in R3|R2|R1.
;
; Operation:         The function divides R16|R17|R18 by R21|R20|R19 using a 
;                    restoring division algorithm with a 24-bit temporary
;                    register R3|R2|R1 and shifting the quotient into 
;                    R16|R17|R18 as the dividend is shifted out.  
;                    Note that the carry flag is the inverted quotient bit (and
;                    this is what is shifted into the quotient) so at the end 
;                    the entire quotient is inverted.
;
; Arguments:         R18|R17|R16 - 24-bit unsigned dividend.
;                    R21|R20|R19 - 24-bit unsigned divisor.
; Return Values:     R18|R17|R16 - 24-bit quotient.
;                    R3|R2|R1    - 24-bit remainder.
;
; Local Variables:   bitcnt (R22) - number of bits left in division.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Registers Changed: flags, R1, R2, R3, R16, R17, R18, R22
; Stack Depth:       0 bytes
;
; Algorithms:        Restoring division.
; Data Structures:   None.
;
; Known Bugs:        None.
; Limitations:       None.
;
; Revision History:   4/15/18   Glen George      initial revision
;                     5/29/26   Emily Wu         revised for 24bit/24bit div

Div24:
        LDI     R22, 24                 ;number of bits to divide into
        CLR     R3                      ;clear temporary register (remainder)
        CLR     R2
        CLR     R1

Div24Loop:                              ;loop doing the division
        ROL     R16                     ;rotate bit into temp (and quotient
        ROL     R17                     ;   into R18|R17|R16)
        ROL     R18
        ROL     R1
        ROL     R2
        ROL     R3
        CP      R1, R19                 ;check if can subtract divisor
        CPC     R2, R20                 
        CPC     R3, R21
        BRCS    Div24SkipSub            ;cannot subtract, don't do it
        SUB     R1, R19                 ;otherwise subtract the divisor
        SBC     R2, R20
        SBC     R3, R21
Div24SkipSub:                           ;C = 0 if subtracted, C = 1 if not
        DEC     R22                     ;decrement loop counter
        BRNE    Div24Loop               ;if not done, keep looping
        ROL     R16                     ;otherwise shift last quotient bit in
        ROL     R17
        ROL     R18
        COM     R16                     ;and invert quotient (carry flag is
        COM     R17                     ;   inverse of quotient bit)
        COM     R18
        ;RJMP   EndDiv24                ;and done (remainder is in R3|R2|R1)

EndDiv24:                               ;all done, just return
        RET



; SetActuator(a, s) ------------------------------------------------------------
; Description:       The function is passed a 3-bit actuator number between 0 
;                    and 7 (a) in R16 that indicates the pinball machine 
;                    actuator to turn on or off. The new state of the actuator 
;                    (s) is passed by value in R17. The corresponding pinball 
;                    machine actuator is turned on if the passed state is TRUE 
;                    (non-zero) and turned off if the passed state is FALSE 
;                    (zero).
;
; Operation:         Left shift an initial mask until the correct actuator bit 
;                    is selected. Then based on whether s is high or low, update
;                    the buffer to set the actuator a to the correct state.   
;
; Arguments:         a - 3 bit actuator number between 0 and 7.
;                    s - new state of actuator (0 = off, 1 = on).
; Return Value:      None.
;
; Local Variables:   None. 
; Shared Variables:  currentActuators - buffer with state of actuators (RD/WR) 
;
; Input:             None.
; Output:            None.
;
; Error Handling:    If a > 7, return. 
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: R16, R17, R21, R22.
; 
; Author:            Emily Wu
; Last Modified:     05/26/26 --------------------------------------------------

SetActuator:
    LDS     R21, currentActuators           ; load buffer with current statuses
    CPI     R16, EXCEEDED_ACTUATOR_NUM           
    BRSH    SetActuatorDone                 ; if a is too large, then return
    ;BRLO   AS_InitMask
AS_InitMask:
    LDI R22, MASK_INIT                      ; build mask, starting from initial

ShiftMask:
    CPI     R16, ACTUATOR_DONE              
    BREQ    MaskComplete                   ; if shifted to correct bit, done
    ;BRNE   AS_MaskContinue
AS_MaskContinue:
    LSL     R22                            ; otherwise, keep shifting
    DEC     R16
    RJMP    ShiftMask

MaskComplete:
    CPI     R17, OFF                       ; determine the state of s (on/off)
    BRNE    ActuatorOn
    ;BREQ   ActuatorOff
ActuatorOff:
    COM     R22                            ; if s off, invert the mask first
    AND     R21, R22                       ; then the LED is ensured to be off
    RJMP    UpdateBuffer

ActuatorOn:
    OR      R21, R22                       ; if s on, LED is ensured to be on

UpdateBuffer:
    STS    currentActuators, R21           ; update actuator buffer

    LDI     R22, NEED_UPDATE               ; indicate update pending
    STS     ActuatorFlag, R22

SetActuatorDone:
    RET

; ReadEEROM(a, p, n) -----------------------------------------------------------
; Description:       The function reads n bytes of data from the 93C46 serial 
;                    EEROM at the passed address (a). The data is stored at the
;                    passed data address (p). The number of bytes (n) is passed 
;                    in R16 by value, the EEROM address (a) is passed in R17 by 
;                    value, and the address at which to store the data (p) is 
;                    passed in Y (R29 | R28) by value (in other words the buffer
;                    is passed by reference). It is assumed that there is enough 
;                    free memory at the passed address to store the bytes read 
;                    by the procedure.
;
; Operation:         Loop as long as n is greater than zero (and a is less than
;                    128). Get the word address through a/2. Perform a single
;                    word read and update HIGH_BYTE & LOW_BYTE by calling 
;                    ReadWord. Check the parity of a. If a is odd, then only
;                    update Y with the high byte. If a is even and n > 1, then
;                    update Y with both the high and low byte. If a is even and
;                    n==1, then update only the low byte in Y. 
;                    Update the n-byte counter and the address after each check.  
;
; Arguments:         a - address at which the data is read (btwn 0 and 127).  
;                    p - address at which to store the read data.
;                    n - number of bytes to read (a+n must be < 128). 
; Return Value:      None.
;
; Local Variables:   None. 
; Shared Variables:  HIGH_BYTE     - byte that has been read from EEROM (RD/WR)
;                    LOW_BYTE      - byte that has been read from EEROM (RD/WR)
;
; Input:             None.
; Output:            None.
;
; Error Handling:    If a + n > 127, then return. If n <= 0, then return. 
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed:  (YL | YH), R16, R17, R18, R19.
; 
; Author:            Emily Wu
; Last Modified:     06/03/26 --------------------------------------------------
ReadEEROM:

ReadLoop:
        CPI     R17, ADDR_EXCEEDED              ; every loop, check if a <= 127
        BRSH    ReadDone                        ; if not, return
        TST     R16                             ; check if n > 0
        BREQ    ReadDone                        ; if not, return

        MOV     R18, R17                        ; transfer address a to temp reg
        LSR     R18                             ; word address = a/2
        RCALL   ReadWord                        ; read a single word at a/2

        SBRC    R17, 0                          ; check if a is odd or even
        RJMP    ReadHighByte                    ; if a is odd, then jump
        ;RJMP   AddressEven                     ; if a is even, then proceed

AddressEven:                                    ; proceed here if a is even
        LDS     R19, LOW_BYTE                   ; first get the low byte read
        ST      Y+, R19                         ;       and store in Y
        DEC     R16                             ; n--
        INC     R17                             ; a++

        TST     R16                             ; check if n has reached 0
        BREQ    ReadDone                        ; n==0 -> we're done
        ;BRNE   ReadHighByte                    ; otherwise, proceed-> high byte

ReadHighByte:                                   ; go directly here if a is odd
        LDS     R19, HIGH_BYTE                  ; get the high byte read
        ST      Y+, R19                         ;       and store in Y
        DEC     R16                             ; n--
        INC     R17                             ; a++
        RJMP    ReadLoop                        ; return to loop start
ReadDone:
        RET

; ReadWord(a) -------------------------------------------------------------
; Description:       Reads a single word from the EEROM at a given address (a).
;
; Operation:         Chip select is made high, and the command to perform a read
;                    at address a is constructed and sent.
;                    The clock generator is triggered and a dummy transfer is
;                    completed to read three bytes of the EEROM. Since the high
;                    byte contains an extraneous zero, we remove the zero and
;                    are left with two bytes of meaningful data. The shared 
;                    variables HIGH_BYTE and LOW_BYTE are updated with the data
;                    that has been read. Chip select is made low.       
;
; Arguments:         a - address at which the data is read (btwn 0 and 127).
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  HIGH_BYTE     - byte that will be read from EEROM (WR)
;                    LOW_BYTE      - byte that will be read from EEROM (WR)
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: R0, R18, R19, R20, R22, R24, R25, R26. 
; 
; Author:            Emily Wu
; Last Modified:     06/03/26 --------------------------------------------------

ReadWord:
        LDI     R19, START_BIT                  ; build read command of the
                                                ;   form: [00000001][ccaaaaaaa]
        LDI     R20, READ_OP_CODE               ; prepare op code
        ANDI    R18, ADDR_MASK                  ; ensure address bits are masked
        OR      R20, R18                        ; concat op code and address

        SBI     PORTB, EE_CS                    ; set chip select HIGH
        NOP
        NOP
        NOP
        NOP

        OUT     SPDR, R19                       ; send the high command byte
        RCALL   SPI_TxRx                        ; wait for transfer
        IN      R0, SPDR                        ; clear the SPIF
        OUT     SPDR, R20                       ; send the low command byte 
        RCALL   SPI_TxRx                        ; wait for transfer
        IN      R0, SPDR                        ; clear the SPIF

        CLR     R22
        OUT     SPDR, R22                       ; send a dummy byte & clk EEPROM
        RCALL   SPI_TxRx                        ; wait for transfer
        IN      R26, SPDR                       ; receive low EEPROM byte
        CLR     R22
        OUT     SPDR, R22                       ; send a dummy byte & clk EEPROM
        RCALL   SPI_TxRx                        ; wait for transfer
        IN      R25, SPDR                       ; receive mid EEPROM byte
        CLR     R22
        OUT     SPDR, R22                       ; send a dummy byte & clk EEPROM
        RCALL   SPI_TxRx                        ; wait for transfer
        IN      R24, SPDR                       ; receive high EEPROM byte

        LSL     R24                             ; since DO has 0 D15..D8 D7..D0, 
        ROL     R25                             ;   we must remove the zero 
        ROL     R26                             

        STS     HIGH_BYTE, R25                  ; update shared variables with 
        STS     LOW_BYTE,  R26                  ;   the read data.

        CBI     PORTB, EE_CS                    ; set chip select low. 
        NOP
        NOP
        NOP
        NOP
        RET                                     ; done with reading the word.

; WriteEEROM(a, p, n) ----------------------------------------------------------
; Description:       The function writes n bytes of data to the 93C46 serial 
;                    EEROM at the passed address (a). The data to be written 
;                    is located at the passed data address (p). The number of 
;                    bytes (n) is passed in R16 by value, the EEROM address (a) 
;                    is passed in R17 by value, and the address where the data 
;                    to be written is stored (p) is passed in Y (R29 | R28) by 
;                    value (in other words the buffer is passed by reference).
;
; Operation:         Perform an Erase/Write enable. Check that a is less than 
;                    128 and that n is greater than 0. Divide a/2 to obtain the
;                    word address. Check the parity of a. If a is odd, then only
;                    write the high byte. If a is even and n == 1, then only
;                    write the low byte. If a is even and n > 1, then write both
;                    the high and low bytes. Update a and n accordingly in all 
;                    cases by incrementing a and decrementing n by 1 in the
;                    single byte write cases, and by 2 in the full word write 
;                    cases. 
;
; Arguments:         a - address at which the data is written (btwn 0 and 127).  
;                    p - address at which the data to be written is stored. 
;                    n - number of bytes to write (a+n must be < 128). 
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  HIGH_BYTE     - byte that will be written to EEROM (RD/WR)
;                    LOW_BYTE      - byte that will be written to EEROM (RD/WR)
;
; Input:             None.
; Output:            None.
;
; Error Handling:    If a + n > 127, then return. If n <= 0, then return. 
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed:  (YL | YH), R16, R17, R18, R19, R20. 
; 
; Author:            Emily Wu
; Last Modified:     06/03/26 --------------------------------------------------

WriteEEROM:
        SBI     PORTB, EE_CS                    ; set chip select high for an
        NOP                                     ;    EraseWrite enable (WEN)
        NOP
        NOP

        LDI     R18, START_BIT                  ; load start bit
        OUT     SPDR, R18
        RCALL   SPI_TxRx
        LDI     R18, WEN_CMD                    ; load op code and address
        OUT     SPDR, R18
        RCALL   SPI_TxRx

        CBI     PORTB, EE_CS                    ; set chip select low
        NOP
        NOP
        NOP

WriteEEROM_LOOP:
        CPI     R17, ADDR_EXCEEDED              ; every loop, check if a <= 127 
        BRSH    WriteEEROM_DONE                 ; if not, return
        TST     R16                             ; check if n > 0
        BREQ    WriteEEROM_DONE                 ; if not, return

        MOV     R18, R17                        ; transfer address a to temp reg
        LSR     R18                             ; word address = a/2

        SBRS    R17, 0                          ; check if a is odd or even
        RJMP    EVEN_ADDRESS                    ; if a is EVEN, then jump

        RCALL   ReadWord                        ; if a is ODD, read a word

        LD      R20, Y+                         ; and store only HIGH_BYTE
        STS     HIGH_BYTE, R20                  ;   so LOW_BYTE remains the same

        RCALL   WriteWord                       ; write only the HIGH byte

        INC     R17                             ; a++
        DEC     R16                             ; n--

        RJMP    WriteEEROM_LOOP                 ; return to loop start. 

EVEN_ADDRESS:
        CPI     R16, SINGLE_BYTE                ; if n == 1, then 
        BREQ    EVEN_SINGLE_BYTE                ;    proceed to single byte case
        ;BRNE   EvenTwoBytes
EvenTwoBytes:
        LD      R20, Y+                         
        STS     HIGH_BYTE, R20                  ; otherwise, store both the high
        LD      R20, Y+                         ;    and the low byte, and
        STS     LOW_BYTE, R20
        RCALL   WriteWord                       ;    write BOTH bytes. 

        SUBI    R17, -2                         ; a += 2 
        SUBI    R16, 2                          ; n -= 2 two bytes were written

        RJMP    WriteEEROM_LOOP                 ; return to loop start. 

EVEN_SINGLE_BYTE:                               ; executes when n == 1
        RCALL   ReadWord                        ; read the entire word at a
        LD      R20, Y+
        STS     LOW_BYTE, R20                   ; only store the low byte 
        RCALL   WriteWord                       ; only write the LOW byte

        INC     R17                             ; a++
        DEC     R16                             ; n--

        RJMP    WriteEEROM_LOOP                 ; return to loop start. 

WriteEEROM_DONE:
        RET

; WriteWord(a) -----------------------------------------------------------------
; Description:       Writes a single word from the EEROM at a given address (a).
;
; Operation:         Recalculate the current word address. Chip select is made
;                    high. The command bytes with the start bit, and the op code
;                    and address, are formed and sent. The clock generator is 
;                    triggered by transmitting the high byte from the shared 
;                    variable HIGH_BYTE. After the transfer is complete, the
;                    same occurs for the low byte. Chip select is made low, sig-
;                    -naling the end of the write command. Chip select is then
;                    asserted again to wait for the write to complete by waiting
;                    for the data output line to go high. Once this occurs, CS
;                    is set low and the function returns.                    
;
; Arguments:         a - address at which the data is written (btwn 0 and 127).
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  HIGH_BYTE     - byte that will be written to EEROM (WR)
;                    LOW_BYTE      - byte that will be written to EEROM (WR)
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: R17, R18, R20.
; 
; Author:            Emily Wu
; Last Modified:     06/03/26 --------------------------------------------------

WriteWord:
        MOV     R18,R17                         ; ensure that R18 gets the word
        LSR     R18                             ;    address

        SBI     PORTB, EE_CS                    ; set chip select high

        LDI     R20, START_BIT                  ; build write command of the
                                                ;   form: [00000001][ccaaaaaaa]
        OUT     SPDR, R20                       ; send the high command byte
        RCALL   SPI_TxRx                        ; wait for transfer

        MOV     R20, R18                        ; make a copy of the word addr
        ANDI    R20, ADDR_MASK                  ; ensure address bits are masked
        ORI     R20, WRITE_OP_CODE              ; concat op code and address
        OUT     SPDR, R20                       ; send the low command byte
        RCALL   SPI_TxRx                        ; wait for transfer

        LDS     R20, HIGH_BYTE                  ; get high byte to be written
        OUT     SPDR, R20                       ; transmit the high byte
        RCALL   SPI_TxRx                        ; wait for transfer
        LDS     R20, LOW_BYTE                   ; get low byte to be written
        OUT     SPDR, R20                       ; transmit the low byte
        RCALL   SPI_TxRx                        ; wait for transfer

        CBI     PORTB, EE_CS                    ; set chip select low
        NOP                                     ; the write command is done
        NOP
        NOP
        SBI     PORTB, EE_CS                    ; set chip select high
        NOP                                     ; poll until ready
        NOP
        NOP
        NOP

WAIT_READY:                                     ; wait for the write to complete
        SBIS    PINB, EE_DO                     ;   which means data output high
        RJMP    WAIT_READY      
        CBI     PORTB, EE_CS                    ; chip select low
        NOP
        NOP
        NOP

RET                                             ; done. 

; InitSPI() --------------------------------------------------------------------
; Description:       Initializes the serial peripheral interface.  
;
; Operation:         Initializes the SPI control register (SPCR) by enabling SPI
;                    and setting up master mode as well as the prescaler. 
;                    Sets up DDRB such that MOSI, the serial clock, and slave
;                    select are outputs. Sets up the SPSR with the double speed
;                    bit high.  
;
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
; Author:            Emily Wu
; Last Modified:     06/02/26 --------------------------------------------------

InitSPI:
        IN      R17, DDRB
        ORI     R17, SPI_DDR            ; ensure that no DDRB bits that were
                                        ;    previously set high are made low.
        OUT     DDRB, R17               
        LDI     R17, SPI_SPCR           ; set the SPI control register configs
        OUT     SPCR, R17
        LDI     R17, SPI_SPSR           ; set the SPI status register configs
        OUT     SPSR, R17
        RET

; SPI_TxRx() -------------------------------------------------------------------
; Description:       Wait for interrupt flag to be set. 
;
; Operation:         Until SPIF is set, keep looping.
;
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
; Author:            Emily Wu
; Last Modified:     05/26/26 --------------------------------------------------

SPI_TxRx:
    SBIS    SPSR, SPIF
    RJMP    SPI_TxRx
    RET

; data segment -----------------------------------------------------------------
.dseg

HIGH_BYTE:        .BYTE  1           ; data read from/written to EEROM
LOW_BYTE:         .BYTE  1           ; data read from/written to EEROM
CurrentActuators: .BYTE  1           ; buffer with current actuator states
ActuatorFlag:     .BYTE  1           ; flag indicating if actuators req. update
