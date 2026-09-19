;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                         Sound Symbol Defs                                  ;
;                            Include File                                    ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the symbol definitions for the pinball machine sound and
; actuator procedures.
;
; Revision History:
;    05/26/26  Emily Wu      	initial revision
;    06/03/26  Emily Wu			added comments


; the data segment -------------------------------------------------------------

.dseg
.equ 	START_BIT		= 1 					; start bit for NM93C46 EEPROM
.equ 	READ_OP_CODE  	= 0b10000000 			; Op Code for read instruction
.equ 	WRITE_OP_CODE 	= 0b01000000 			; Op Code for write instruction
.equ 	ADDR_MASK 		= 0b00111111 			; address should be A5-A0

; PlayNote (uses Timer1)
.equ 	TOGGLE 			= (1 << COM1A0) 		; toggle OC1A on Compare Match 
.equ    CTC    			= (1 << WGM12) 			; waveform generation mode: CTC
.equ 	PRESCALE 		= 0b010 				; set clk prescaler
;.equ 	FREQ_FACTOR  	= 500000			   	; =(CPU frequency)/(2*prescale)
.equ 	SPEAKER_PIN 	= PB5 					; speaker uses PB5/OC1A

; SetActuators
.equ 	ACT_LATCH_CLK 			= PA5 			; pin for TPIC6273 latch clock 
.equ 	MASK_INIT 				= 0b00000001 	; initial actuator mask 
.equ 	EXCEEDED_ACTUATOR_NUM	= 8 			; noninclusive actuator num max
.equ 	ACTUATOR_DONE 			= 0 			; used for completing mask shift
.equ 	OFF 					= 0 			; see if actuator state is off 
.equ 	BLANK 					= 0b00000000 	; actuators start off blank
.equ 	NEED_UPDATE 			= 1 			; indicates if actuators need
												; 	to be updated.

; InitSPI
.equ 	DDR_SPI 		= DDRB 					; DDR containing SPI pins
.equ 	DD_MOSI 		= DDB2 					; master out/slave in pin
.equ 	DD_SCK 			= DDB1 					; serial clock pin
.equ 	DD_SS 			= DDB0 					; slave select pin
.equ    SPI_DDR  = (1<<DD_SS)|(1<<DD_MOSI)|(1<<DD_SCK) ; config outputs 
.equ    SPI_SPCR = (1<<SPE)|(1<<MSTR)|(1<<SPR0) ; enable SPI, set master mode,
												; 	 and set prescale
.equ    SPI_SPSR = (1<<SPI2X)					; set double speed bit

; EEROM
.equ 	ADDR_EXCEEDED			= 128 			; noninclusive address maximum
.equ 	EE_CS 					= PB0 			; EEROM chip select pin
.equ 	EE_DO 					= PB3 			; EEROM data output pin
.equ 	WEN_CMD 				= 0x30			; op code and address for WEN 
.equ 	SINGLE_BYTE 			= 1 			; when n == 1, only 1 byte left


; PWM
.equ PRESCALE_BITS = 0b010          ; clk/8
.equ PRESCALE_VAL  = 8

.equ FREQ_FACTOR   = 2000000        ; 16MHz/8
