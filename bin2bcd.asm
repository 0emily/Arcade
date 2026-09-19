;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                     BIN2BCD                                ;
;                              Conversion Routine                            ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; This file contains a function for converting from bin2bcd
;
; Revision History:   4/16/18   Glen George      initial revision
;                     4/22/22   Glen George      use a loop for rotation
;                     6/12/25   Glen George      fixed bug - mixed up return
;                                                   values for Div16
;                     6/15/26   Emily Wu         added file header

.cseg
; Bin2BCD
;
;
; Description:       This function converts the 16-bit binary value passed to
;                    it to BCD (4-digits) and returns that result.  If there
;                    is an overflow (the number is bigger than 9999), the
;                    carry flag is set.  The number is assumed to be positive.
;
; Operation:         The function starts with the largest power of 10 possible
;                    (1000) and loops dividing the number by the power of 10,
;                    the quotient is a digit and the remainder is used in the
;                    next iteration of the loop.  Each loop iteration divides
;                    the power of 10 by 10 until it is 0.  At that point the
;                    number has been converted to BCD.
;
; Arguments:         R17|R16 - binary value to convert to BCD.
; Return Values:     R19|R18 - BCD of binary value passed in R17|R16.
;                    CF      - set to 1 if passed value > 9999 (decimal), 0
;                              otherwise.
;
; Local Variables:   digit (R3|R2)    - computed BCD digit (R3 always 0).
;                    error (CF)       - error flag.
;                    pwr10 (R21|R20)  - current power of 10 being computed.
;                    result (R19|R18) - BCD result from conversion.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    If the number to be converted is greater than 9999 the
;                    carry flag is set and a meaningless value is returned.
;
; Registers Changed: flags, R2, R3, R4, R5, R16, R17, R18, R19, R20, R21, R22
; Stack Depth:       0 words
;
; Algorithms:        Repeatedly divide by powers of 10 and get the remainders
;                    (which are the BCD digits).
; Data Structures:   None.
;
; Known Bugs:        None.
; Limitations:       Can only handle positive numbers which are less than
;                    9999.
;
;
;
; Pseudo Code
;
;   result = 0
;   pwr10 = 1000
;   error = FALSE
;   WHILE ((error = FALSE) AND (pwr10 != 0))
;       digit = arg/pwr10
;       IF (digit < 10) THEN
;           result = result shifted left 4 bits OR digit
;           arg = arg MODULO pwr10
;           pwr10 = pwr10/10
;           error = FALSE
;       ELSE
;           error = TRUE
;       ENDIF
;   ENDWHILE
;   RETURN  error, result


Bin2BCD:

Bin2BCDInit:                            ;initialization
        LDI     R20, LOW(1000)          ;start with 10^3 (1000's digit)
        LDI     R21, HIGH(1000)
        CLC                             ;no error yet
        ;RJMP   Bin2BCDLoop             ;now start looping to get digits


Bin2BCDLoop:                            ;loop getting the digits in arg
        BRCS    EndBin2BCDLoop          ;if there is an error - we're done
        MOV     R22, R21                ;check if pwr10 != 0
        OR      R22, R20
        BREQ    EndBin2BCDLoop          ;if not, have done all digits, done
        ;RJMP   Bin2BCDLoopBody         ;else get the next digit

Bin2BCDLoopBody:                        ;get a digit
        RCALL   Div16                   ;digit = arg/pwr10, arg = arg % pwr10
        CPI     R16, 10                 ;check if digit < 10 (upper 8 bits always 0)
        BRSH    TooBigError             ;if not, it's an error
        ;BRLO   HaveDigit               ;otherwise process the digit

HaveDigit:                              ;put the digit into the result
        LDI     R22, 4                  ;shift result to make room for new
ShiftLoop:                              ;   digit (need to shift 16-bit value
        CPI     R22, 1                  ;   left by 4)
        BRLO    DoneShift
        ;BRSH   DoShift
DoShift:                                ;shift 16-bit value left one bit
        LSL     R18
        ROL     R19
        DEC     R22                     ;update loop counter
        RJMP    ShiftLoop               ;and loop

DoneShift:
        OR      R18, R16                ;and actually or in the digit

        MOVW    R4, R2                  ;temporarily save remaining value to convert
        MOVW    R16, R20                ;setup to update pwr10
        LDI     R20, LOW(10)            ;will divide by 10
        LDI     R21, HIGH(10)
        RCALL   Div16                   ;divide pwr10 by 10
        MOVW    R20, R16                ;pwr10 = pwr10/10
        MOVW    R16, R4                 ;restore value to convert too
        CLC                             ;no error
        RJMP    EndBin2BCDLoopBody      ;done getting this digit

TooBigError:                            ;the value was too big
        SEC                             ;set the error flag
        ;RJMP   EndBin2BCDLoopBody      ;and done with this loop iteration

EndBin2BCDLoopBody:
        RJMP    Bin2BCDLoop             ;keep looping (end check is at top)


EndBin2BCDLoop:                         ;done converting, just return
        RET
