;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                         Pinball Symbol Defs                                ;
;                            Include File                                    ;
;                            Homework #5                                     ;
;                             EE/CS 10b                                      ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the symbol definitions for the pinball machine procedures.
; 
;
; Revision History:
;    06/09/26  Emily Wu      	Initial Revision
;    06/10/26  Emily Wu         added initiation variables
;    06/11/26  Emily Wu         added score & main sensor reaction variables
;    06/12/26  Emily Wu         added sound/music variables
;    06/14/26  Emily Wu         revised comments


; the data segment -------------------------------------------------------------

.dseg
; game initialization ----------------------------------------------------------
.equ 	MAX_PLAYERS 			= 4 		; pinball machine supports 4 players
.equ 	MAX_ROUNDS				= 5			; after each player plays 5 rounds, 
											; 	 game ends. 						
.equ 	SCORE_BUFFER_SIZE 		= 8 		; 2 bytes * 4 players max = 8
.equ 	BACK_TO_START 			= 1 		; pointer moves back to score start
.equ 	MAX_SCORE 				= 9999 		; maximum displayable score
.equ 	CMD_ENTRY_SIZE 			= 4 		; the size of each cmd table entry

; high score -------------------------------------------------------------------
.equ 	NO_NEW_HIGHSCORE 		= 0 		; no high score from this game
.equ 	NEW_HIGHSCORE 			= 1 		; new high score from this game
.equ 	HIGH_SCORE_ADDRESS 		= 0x00 		; address where high score is stored
.equ 	SCORE_BYTE_LEN 			= 2 		; score byte length

; point values -----------------------------------------------------------------
.equ 	YG_CHANGE_PTS 			= 10 		; pts for yellow/green change sensor
.equ    ACES_KINGS_PTS 			= 10 		; pts for hitting aces/kings
.equ 	RGY_PTS 				= 10 		; pts for red/green/yellow bumpers
.equ 	JOKER_LINE_PTS 			= 10 		; pts for yellow/green joker lines
.equ 	LITES_YG_PTS 			= 100 		; pts for lites yellow/green
.equ 	LITES_YG_EXTRA_PTS		= 200 		; add'l pts for lites yellow/green 

; round initialization ---------------------------------------------------------
.equ 	LIGHT_ON 				= 1 		; value of an LED that is on
.equ 	LIGHT_OFF 				= 0 		; value of an LED that is off
.equ 	NO_EXTRA_BALL			= 0 		; player does not have an extra ball
.equ 	EXTRA_BALL_TRUE 		= 1  		; player does get an extra ball
.equ 	JOKER_COUNTER_INIT 		= 1 		; joker counter starts @ 1st LED
.equ 	COLUMN_CALC 			= 7 

.equ 	FIRST_PLAYER			= 1 		; number of the starting player 
.equ 	FIRST_ROUND				= 1 		; number of the starting round
.equ 	PLAYING_FALSE 			= 0 		; game state when not playing
.equ 	PLAYING_TRUE 			= 1 		; game state when playing

; actuators --------------------------------------------------------------------
.equ 	ACTUATOR_ON 			= 1 		; value for active actuator
.equ 	ACTUATOR_OFF 			= 0 		; value for deactivated actuator
.equ 	ACTUATOR_DELAY 			= 1000 		; actuator delay is 1000 ms, or 1s
.equ 	NUM_ACTUATORS 			= 8 		; total number of actuators

; music ------------------------------------------------------------------------
.equ 	NUM_LOOPS 				= 2 		; number of times to loop the tune
.equ 	SUCCESS_NOTE_LEN 		= 200 		; length of high score notes (ms)
.equ 	MUSIC_NOTE_LEN 			= 200 		; length of game music notes (ms)

; joker ------------------------------------------------------------------------
.equ 	JOKER_MAX 				= 10 		; the maximum number of LEDs on 1
	                                        ;     side of the joker lines
.equ 	RIGHT_SIDE 				= 1 		; right/yellow side
.equ 	LEFT_SIDE 				= 0 		; left/green side	
.equ 	CAVITY_DELAY 			= 200 		; time for cavity actuator (ms)

; actuator/sound timer numbers -------------------------------------------------
.equ 	CAVITY_TIMER   			= 8  		; timer num for cavity actuator
.equ 	SUCCESS_TIMER 			= 7 		; timer num for new high score music
.equ 	MUSIC_TIMER 			= 6 		; timer num for in-game music

 ; light number -> row = l//8 --------------------------------------------------
.equ    KH_ROW  = KingofHeartsLED/8 		; kings 
.equ    KD_ROW  = KingofDiamondsLED/8
.equ    KC_ROW  = KingofClubsLED/8
.equ    KS_ROW  = KingofSpadesLED/8

.equ    AH_ROW  = AceofHeartsLED/8 			; aces 
.equ    AD_ROW  = AceofDiamondsLED/8
.equ    AC_ROW  = AceofClubsLED/8
.equ    AS_ROW  = AceofSpadesLED/8

.equ 	INC_Y_ROW = IncreasesValY/8 		; "increases value when lit" LEDs
.equ 	INC_G_ROW = IncreasesValG/8

.equ Y300_ROW  = YPoints300/8 				; "300 points when lit" LEDs
.equ G300_ROW  = GPoints300/8

; light number -> col = l % 8 --------------------------------------------------
.equ    KH_MASK = (1<<(KingofHeartsLED&7)) 	; kings
.equ    KD_MASK = (1<<(KingofDiamondsLED&7))
.equ    KC_MASK = (1<<(KingofClubsLED&7))
.equ    KS_MASK = (1<<(KingofSpadesLED&7))

.equ    AH_MASK = (1<<(AceofHeartsLED&7)) 	; aces
.equ    AD_MASK = (1<<(AceofDiamondsLED&7))
.equ    AC_MASK = (1<<(AceofClubsLED&7))
.equ    AS_MASK = (1<<(AceofSpadesLED&7))

.equ 	INC_Y_MASK = (1<<(IncreasesValY&7)) ; "increases value when lit" LEDs
.equ 	INC_G_MASK = (1<<(IncreasesValG&7))

.equ Y300_MASK = (1<<(YPoints300&7)) 		; "300 points when lit" LEDs
.equ G300_MASK = (1<<(GPoints300&7))


; LED light numbers ------------------------------------------------------------
.equ	GameOver			= 56
.equ	BallinPlay1			= 64
.equ	BallinPlay2			= 65
.equ	BallinPlay3			= 66
.equ	BallinPlay4			= 67
.equ	BallinPlay5			= 68
.equ	RedLED				= 29
.equ	GreenLED			= 28
.equ	YellowLED			= 31
.equ	GPoints300			= 35
.equ	YPoints300			= 34
.equ	IncreasesValG		= 26
.equ	IncreasesValY		= 39
.equ	KingofHeartsLED		= 37
.equ	KingofDiamondsLED	= 36
.equ	KingofClubsLED		= 32
.equ	KingofSpadesLED		= 33
.equ	AceofHeartsLED		= 20
.equ	AceofDiamondsLED	= 21
.equ	AceofClubsLED		= 22
.equ	AceofSpadesLED		= 23
.equ	YellowJoker10x		= 3
.equ	GreenJoker10x		= 27
.equ	Y10					= 8
.equ	Y20					= 9
.equ	Y30					= 10
.equ	Y40					= 11
.equ	Y50					= 6
.equ	Y60					= 5
.equ	Y70					= 4
.equ	Y80					= 0
.equ	Y90					= 1
.equ	Y100				= 2
.equ	G10					= 12
.equ	G20					= 13
.equ	G30					= 14
.equ	G40					= 19
.equ	G50					= 18
.equ	G60					= 17
.equ	G70					= 16
.equ	G80					= 51
.equ	G90					= 52
.equ	G100				= 53
.equ	extraBallL			= 25
.equ	extraBallR			= 38
.equ	SamePlayerShootsAgain= 107

; Sensor codes -----------------------------------------------------------------
.equ	StartGame			= 0x07
.equ	KingofHearts		= 0x06
.equ	LowerYellowChange	= 0x05
.equ	TriangularIslandsR	= 0x04
.equ	UpperYellowChange	= 0x03
.equ	LitesYellowJoker	= 0x02
.equ	KingofSpades		= 0x01
.equ	KingofClubs			= 0x00
.equ	KingofDiamonds		= 0x87
.equ	SideExitsR			= 0x86
.equ	SideExitsL			= 0x85
.equ	Wheel				= 0x84
.equ	TriangularIslandsL	= 0x47
.equ	LowerGreenChange	= 0x46
.equ	AceofHearts			= 0x45
.equ	AceofDiamonds		= 0x44
.equ	AceofClubs			= 0x43
.equ	AceofSpades			= 0x42
.equ	UpperGreenChange	= 0x41
.equ	LitesGreenJoker		= 0x40
.equ	BallCavityL			= 0x27
.equ	BallCavityR			= 0x26
.equ	Green				= 0x25
.equ	Red					= 0x24
.equ	Yellow				= 0x22
.equ	Tilt				= 0x21
.equ	Exit				= 0x20
.equ 	FlipperL 			= 0x17

; These are the sensorCodes and their corresponding switches:
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

; Actuator numbers -------------------------------------------------------------
.equ 	BallCavityLActuator = 0b000000000
.equ 	BallCavityRActuator = 0b000000001
.equ 	FlipperLAct			= 0b000000010
.equ 	FlipperRAct 		= 0b000000011
.equ 	PostAct 			= 0b000000100
.equ 	RedAct 				= 0b000000101
.equ 	GreenAct			= 0b000000110
.equ 	YellowAct 			= 0b000000111