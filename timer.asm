;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                    TIMER                                   ;
;                               Timing Routines                              ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the general AVR timing functions.  The functions can be
; used to create up to TIMER_CNT simultaneous timers.  It is assumed that the
; TimerHandler function is called every millisecond to keep track of time.
; The functions included are:
;    DelayNotDone - a previously started delay is not done yet
;    InitTimers   - initialize the timing system
;    StartDelay   - start timing a delay (start a timer)
;    TimerHandler - timer 0 overflow handler
;
; Revision History:
;     1/25/10  Glen George              initial revision
;     1/26/10  Glen George              now allow multiple delay timers
;     1/31/10  Glen George              added frequency meter updates
;     2/3/10   Glen George              updated comments
;     8/22/10  Glen George              moved frequency meter checks into
;					   frequency code
;     7/23/12  Glen George              generalized the functions for use in
;					   any program
;     7/28/12  Glen George              updated comments
;     9/30/13  Glen George              added inclusion of timer.inc



; local include files
;.include  "timer.inc"

.cseg

; InitTimers
;
; Description:       This function initializes the timing system.
;
; Operation:         This function initializes the variables for the timing
;                    system.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  delayTimer - written (all bytes reset to 0).
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: flags, R16, R17, X (XH | XL)
; Stack Depth:       0 bytes
;
; Author:            Glen George
; Last Modified:     July 23, 2012

InitTimers:

	CLR	R16			;clear the timer value
	CLR	R17			;and the timer counter
	LDI	XL, LOW(delayTimer)	;point to the timer data
	LDI	XH, HIGH(delayTimer)

InitTimerLoop:				;loop setting all bytes to 0
	ST	X+, R16
	INC	R17			;count the timer bytes
	CPI	R17, 2 * TIMER_CNT	;there are 2 bytes per timer
	BRLO	InitTimerLoop		;loop while still have bytes to clear
	;BRSH	EndInitTimers		;if done setting up timers, done


EndInitTimers:                          ;done initializing the timers - return
        RET




; StartDelay
;
; Description:       This function starts a delay interval.  DelayNotDone will
;                    return false after the passed number of milliseconds has
;                    elapsed for the passed timer.  The passed timer number
;                    must be valid (0 to TIMER_CNT - 1) or no timer is
;                    started.  The maximum delay is 65.535 seconds.
;
; Operation:         The passed delay argument is stored in the appropriate
;                    delayTimer element.
;
; Arguments:         R16 - the number of the timer to be started, must be
;                          between 0 and TIMER_CNT - 1.
;                    X   - the delay in milliseconds.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  delayTimer - written (passed timer's count is changed).
;
; Input:             None.
; Output:            None.
;
; Error Handling:    If the passed timer number is out of range, no timer is
;                    changed.	
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: flags, R16, Y (YH | YL)
; Stack Depth:       0 bytes
;
; Author:            Glen George
; Last Modified:     July 23, 2012

StartDelay:

CheckArgs:				;check the timer number
	CPI	R16, TIMER_CNT
	BRSH	EndStartDelay		;if out of range do nothing
	;BRLO	SetupDelayTimer		;otherwise setup the delay timer


SetupDelayTimer:			;setup the delay timer
	LSL	R16			;two bytes per timer

	LDI	YL, LOW(delayTimer)	;get the address of the timer
	LDI	YH, HIGH(delayTimer)
	ADD	YL, R16
	BRCC	DoneTimerCarry		;no carry to propagate
	INC	YH			;propagate carry
DoneTimerCarry:

	ST	Y+, XL			;store the new delay time
	ST	Y+, XH


EndStartDelay:				;done setting up delay, return
        RET




; DelayNotDone
;
; Description:       This function returns true if the delay time has not
;                    passed since StartDelay was called for the passed timer
;                    number (must be between 0 and TIMER_CNT - 1).  False is
;                    returned if the delay has elapsed.
;
; Operation:         The function or's the bytes of the appropriate delayTimer
;                    element into R0 which can then be checked for 0.
;
; Arguments:         R16 - the number of the timer to be checked, must be
;                          between 0 and TIMER_CNT - 1.
; Return Value:      R0 - true (non-zero) if the delay time has not elapsed
;                         since StartDelay was called for this timer and false
;                         (zero) if the delay time has elapsed.
;                    ZF - set iff the delay time has elapsed for this timer.
;
; Local Variables:   None.
; Shared Variables:  delayTimer - read only.
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    If the timer number is out of range (greater than or
;                    equal to TIMER_CNT), false is returned.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: flags, R0, R16, Y (YH | YL)
; Stack Depth:       0 bytes
;
; Author:            Glen George
; Last Modified:     August 22, 2010

DelayNotDone:


CheckStatusArgs:			;check the timer number
	CPI	R16, TIMER_CNT
	BRSH	InvalidTimer		;handle out of range timer
	;BRLO	SetupTimerCheck		;otherwise setup to check the timer


SetupTimerCheck:			;setup to check the delay timer
	LSL	R16			;two bytes per timer

	LDI	YL, LOW(delayTimer)	;get the address of the timer
	LDI	YH, HIGH(delayTimer)
	ADD	YL, R16
	BRCC	CheckTimer		;no carry, check the timer
	INC	YH			;otherwise, propagate carry
	;RJMP	CheckTimer		;then check the timer


CheckTimer:				;check the timer
        LDD	R0, Y + 1		;get the bytes of the delay timer
	LD	R16, Y			;get high byte first to avoid critical code

	OR	R0, R16			;or bytes together to set R0 to T/F
	RJMP	EndDelayNotDone		;  (also sets ZF) and done


InvalidTimer:				;illegal timer number, return false
	CLR	R0			;assumes FALSE is 0 and handles ZF too
	;RJMP	EndDelayNotDone		;and done


EndDelayNotDone:                        ;done figuring out if delay is done
        RET




; TimerHandler
;
; Description:       This is the handler for the timing system.  It is
;                    expected that this function will be called every
;                    millisecond.
;
; Operation:         Any non-zero delay times are decremented.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  delayTimer - read and possibly written.
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: flags, R18, R19, R20, R21, X (XH | XL)
; Stack Depth:       0 bytes
;
; Author:            Glen George
; Last Modified:     July 23, 2012

TimerHandler:

StartTmrHandler:			;update the delay timers if non-zero
	LDI	XL, LOW(delayTimer)	;get the timer address
	LDI	XH, HIGH(delayTimer)
	LDI	R18, TIMER_CNT		;number of timers to update

TimerUpdateLoop:			;loop updating the timers

	LD	R19, X+			;check if delay timer is done
	LD	R20, X+			;get both bytes
	MOV	R21, R19		;and check for zero
	OR	R21, R20
	BREQ	DoneTimer		;if so done with this timer
	;BRNE	DecTimer		;otherwise it needs to be decremented

DecTimer:				;decrement the delay timer
	SUBI	R19, 1			;decrement low byte
	SBCI	R20, 0			;propogating into high byte if needed
	SBIW	X, 2			;get pointer back to start of timer
	ST	X+, R19			;and store new timer value
	ST	X+, R20
	;RJMP	DoneTimer		;and done with this timer

DoneTimer:				;done decrementing this timer
	DEC	R18			;update the timer counter
	BRNE	TimerUpdateLoop		;if not done, do the next timer
	;BREQ	DoneTmrHandler		;otherwise done with the handler


DoneTmrHandler:				;done with handler, return
	RETI				;and return




;the data segment


.dseg


delayTimer:	.BYTE  2 * TIMER_CNT	;array of delay timers (2 bytes/timer)