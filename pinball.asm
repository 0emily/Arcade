;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                    	   Pinball Functions  	                             ;
;                            Homework #5                                     ;
;                             EE/CS 10b                                      ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains functions pertinent to the main pinball implementation. 
; The functions included are:
;    InitPinball()      - initializes game-starting variables. 
;    Flipper()          - If not currentlyPlaying, updates intended number of 
;                         players in the game and displays it on a hex display.
;    StartButton()      - Inits game, sets currentlyPlaying high, & inits round. 
;    InitGame()         - Initializes the music, round, and player variables. 
;                         Clears the score buffer; sets player displays to 0000. 
;    InitRound()        - Initializes the LEDs, flags, and counters for a round.
;    Main()             - If a sensor is activated, searches through cmd tables
;                         for the sensor code & calls its associated functions. 
;    UpdatePlayerRound()- Updates the player & round; stays on same player if 
;                         they have earned an extra ball. 
;    EndGame()          - Sets up end-of-game LEDs, gets & displays high score,
;                         and plays sound if a new high score was set. 
;    PlaySuccess()      - Loops and plays a melody a specified number of times. 
;    UpdateScore(points)- Updates/displays current player's score by {points}. 
;    YellowGreenChange()- Updates the lights corresponding to the Yellow and Gr-
;                         -een "change" sensors, as well as the score. 
;    AcesKings(l)       - Turns of the LED associated with the sensor when hit,
;                         updates the score, and turns on the extraBall LEDs & 
;                         flag when all Aces or all Kings are hit. 
;    RedGreenYellow()   - Turns on yellow/green LEDs if the sensor are hit, 
;                         updates points, and activates corresponding actuators.
;    WheelHit()         - Lights up one more LED on either the yellow or green
;                         joker side, or keeps all LEDs lit if the line is fully
;                         lit already. 
;    ActuatorTurnOn(n)  - Turns on one actuator for a specified amount of time.
;    ActuatorHandler    - Checks if a delay is done; if so, turns actuator off.
;    BallCavity()       - Activates the ball cavity actuator and caches previou-
;                         -sly earned points on the same-side joker line. 
;    BallCavityHandler()- Turns off LEDs on the active joker line one by one. 
;    SetHighScore()     - determines if a new high score was set in a game &
;                         updates the EEROM accordingly.
;    LitesYellowGreen() - updates score by a base amount for rolling over the s-
;                         -ensor. If the rolled over sensor is the same color as
;                         the currently lit "300 points when lit," extra pts are
;                         then awarded. 
;    StartMusic()       - Ensures that music starts on the first note. 
;    MusicHandler()     - Plays background music continuously while players play
;
; Revision History:
;    06/09/26  Emily Wu         Initial revision [used ChatGPT free version]
;    06/10/26  Emily Wu         able to set number of players & start game
;    06/11/26  Emily Wu         able to update score and do non-EC functions
;    06/12/26  Emily Wu         added sound (PWM, game music, high score music)
;    06/13/26  Emily Wu         revised comments, removed duplicate code in main
;    06/14/26  Emily Wu         revised comments


; code segment -----------------------------------------------------------------
.cseg
; InitPinball() ----------------------------------------------------------------
; Description:       Initializes shared variables for pinball machine. 
;
; Operation:         Sets game state to not currently playing and the number of
;                    players to the specified number for the first player. 
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  currentlyPlaying - flag indicating if game is ongoing [WR]
;                    numPlayers - total num players for this game [1-4] [WR]
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
; Last Modified:     6/10/2026--------------------------------------------------

InitPinball:
    LDI     R16, PLAYING_FALSE        
    STS     currentlyPlaying, R16               ; set currentlyPlaying to false

    LDI     R16, FIRST_PLAYER      
    STS     numPlayers, R16                     ; init value for numPlayers

    RET
; Flipper() --------------------------------------------------------------------
; Description:       If the left flipper button is pressed while currentlyPlayi-
;                    -ng is false, the number of presses will indicate the numb-  
;                    -er of desired players in the game. 
;
; Operation:         The left flipper may only be used to set the number of pla-
;                    -yers if a game is not currently ongoing, as indicated by 
;                    the currentlyPlaying flag. Each time this function is call-
;                    -ed, the number of players increments by 1. If the maximum 
;                    number of players has been reached, the number of players  
;                    loops back to 1. 
;                    The 1st hex display updates to show the number of players. 
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  currentlyPlaying - flag indicating if game is ongoing [RD]
;                    numPlayers - total num players for this game [1-4] [RD/WR]
;
; Input:             None.
; Output:            The 1st hex display updates w/ the selected player number.
;
; Error Handling:    The number of players must be between 1 and 4 inclusive. 
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: R16, R17, R18, R19. 
;
; Author:            Emily Wu
; Last Modified:     6/13/2026--------------------------------------------------

Flipper:
        LDS     R16, currentlyPlaying      ; check if game is active as indicat-
        TST     R16                        ;    -ed by the currentlyPlaying flag
        BRNE    FlipperDone                ; if game is active, done
        ;BREQ   FlipperContinue            ; if game inactive, change player cnt

FlipperContinue:
        LDS     R16, numPlayers            ; get the current player count
        CPI     R16, MAX_PLAYERS           ; check if at the max player count
        BRSH    FlipperReset               ; wrap if already at max players
        ;BRLO   FlipperInc                 ; otherwise increment player cnt

FlipperInc:
        INC     R16                        ; increment the number of players
        RJMP    FlipperUpdateDisplay       ; display this number

FlipperReset:
        LDI     R16, FIRST_PLAYER          ; wrap back to 1st player

FlipperUpdateDisplay:
        STS     numPlayers, R16            ; save updated player count

        CLR     R17                        ; 16-bit bin value in R17:R16
        RCALL   Bin2BCD                    ; convert to BCD value

        MOVW    R16:R17, R18:R19           ; DisplayHex takes value in R17:R16
                                           ; but BCD result is in R19:R18

        LDI     R18, FIRST_PLAYER          ; display on first display
        RCALL   DisplayHex

FlipperDone:
        RET


; StartButton() ----------------------------------------------------------------
; Description:       When the start button is pressed, the game state becomes an 
;                    active game. The game and first round are initialized. 
;
; Operation:         Initialize the system for a game by calling InitGame(). Set
;                    the currentlyPlaying flag to high and init the first round. 
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  currentlyPlaying - flag indicating if game is ongoing [WR]
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
; Last Modified:     6/13/2026--------------------------------------------------

StartButton:
        RCALL   InitGame                      ; initialize game

        LDI     R16, PLAYING_TRUE             ; get game active value
        STS     currentlyPlaying, R16         ; indicate we're currently playing

        RCALL   InitRound                     ; initialize first round

        RET

; InitGame() -------------------------------------------------------------------
; Description:      Initializes a full game, which consists of between 1 and 4
; 		    players (inclusive) where each player plays 5 rounds (exce-
; 		    -pting if extra balls are earned during gameplay, in which
;                   case a player may immediately earn an extra round). 
;
; Operation:        The variables for starting music are set. The score 0000 is 
; 		    displayed for all players who are playing. The remaining 
;                   hex displays are kept off. Any previous scores that have 
; 		    been stored in currentScores are cleared. The current 
; 		    player and round are initialized. By default, the game
; 		    does not start until the start button is pressed, so the 
; 		    game state is initialized to indicate not currently playing.                   
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  currentPlayer   - player currently active [1-4] [WR]
; 		     currentRound     - current round [1-5] [WR]
; 		     currentlyPlaying - flag indicating if game is ongoing [WR]
; 		     currentScores    - buffer containing all player's scores  
; 				        for a single game [WR]
;
; Input:             None.
; Output:            Displays 0000 on all active player's hex displays. 
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: Z (ZH | ZL), R16, R17, R18, R19
;
; Author:            Emily Wu
; Last Modified:     6/13/2026 -------------------------------------------------

InitGame:
        RCALL StartMusic                     ; begin playing game music

        LDI     ZH, HIGH(currentScores)      ; load the current score buffer
        LDI     ZL, LOW(currentScores)       ;    into the Z pointer
        CLR     R16                          ; the score buffer will be cleared
        LDI     R17, SCORE_BUFFER_SIZE       ; init counter w/ score buffer len                 

IG_Clear:
        ST      Z+, R16                      ; clear the first byte of a score
        DEC     R17                          ; decrease the size counter
        BRNE    IG_Clear                     ; keep looping to clear all bytes
        ;BREQ   IG_InitDisplay               ; once equal, set up vars 

IG_InitDisplay:
        LDS     R19, numPlayers              ; get num of players for this game
        LDI     R18, FIRST_PLAYER            ; begin with 1st player

IG_Display:
        CLR     R16                          ; we wish to display 0000 for all 
        CLR     R17                          ;    players

        PUSH    R18                          ; preserve current player # and
        PUSH    R19                          ;    total number of players

        RCALL   DisplayHex                   ; display 0000 for current player

        POP     R19                          ; get back player # & num players
        POP     R18

        INC     R18                          ; move on to the next player 
        CP      R18, R19                     ; check if we're at the last player
        BRLO    IG_Display                   ; loop if we're within num players
        ;BRSH   IG_CheckLast                 ;    otherwise check equality

IG_CheckLast:
        BREQ    IG_Display                   ; still keep looping if equal
        ;BRNE   IG_Done                      ;    otherwise done

IG_Done:
        LDI     R16, FIRST_PLAYER            ; game should start @ first player
        STS     currentPlayer, R16           ; update the currentPlayer w/ this

        LDI     R16, FIRST_ROUND             ; game should start @ fist round
        STS     currentRound, R16            ; update the currentRound w/ this

        LDI     R16, PLAYING_FALSE           ; we're not currently playing bc 
        STS     currentlyPlaying, R16        ;   the start button hasn't been
                                             ;   pressed. 
        RET

; InitRound() ------------------------------------------------------------------
; Description:       Initializes a single round in a game, including LEDs,
;                    flags, and counters. 
;
; Operation:         Initializes the extra ball flag to be false. Initializes
; 		     all LEDs that begin the round as on. Resets other LEDs 
;                    that have been set on in the previous round to be off. 
; 		     The counters for the green/yellow jokers are additionally
;                    initialized to 1. 
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  extraBall - flag: current player gets 1 extra ball [WR]
; 		     yellowCounter - cntr for 10-100 LED line: yellow joker [WR]
; 		     greenCounter - cntr for 10-100 LED line: green joker [WR]
;
; Input:             None.
; Output:            Turns all LEDs off except for the LEDs that are always on 
;                    at the start of a round. 
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: z (ZH | ZL), R16, R17, R18. 
;
; Author:            Emily Wu
; Last Modified:     6/13/2026--------------------------------------------------

InitRound:
        LDI     ZH, HIGH(2*RoundInitLEDsON)  ; get the start of the table
        LDI     ZL, LOW(2*RoundInitLEDsON)   ;   which has LEDs to turn on

        LDI     R18, ROUND_INIT_ON_COUNT     ; counter: num of LEDs/table length
        LDI     R17, LIGHT_ON                ; would like these LEDs to be on

IR_OnLoop:
        LPM     R16, Z+                      ; get the next light number                  

        PUSH    ZH                           ; preserve the Z register
        PUSH    ZL
        RCALL   DisplayLight                 ; display the current LED (on)
        POP     ZL
        POP     ZH

        DEC     R18                          ; decrement the LED number counter
        BRNE    IR_OnLoop                    ; if counter nonzero, loop
        ;BREQ   IR_Off                       ; if counter zero, move onto LEDs
                                             ;    that should be off

IR_Off:
        LDI     ZH, HIGH(2*RoundInitLEDsOFF) ; get the start of the table that 
        LDI     ZL, LOW(2*RoundInitLEDsOFF)  ;    has the LEDs to turn off

        LDI     R18, ROUND_INIT_OFF_COUNT    ; counter: num of LEDs/table length
        LDI     R17, LIGHT_OFF               ; would like these LEDs to be off

IR_OffLoop:
        LPM     R16, Z+                      ; get the next light number

        PUSH    ZH                           ; preserve the Z register
        PUSH    ZL
        RCALL   DisplayLight                 ; display the current LED (off)
        POP     ZL
        POP     ZH

        DEC     R18                          ; decrement the LED number counter
        BRNE    IR_OffLoop                   ; if counter nonzero, loop
        ;BREQ   IR_FlagCounterInit           ; if counter zero, move onto flags
                                             ;    and counters

IR_FlagCounterInit:
        LDI     R16, NO_EXTRA_BALL           ; initialize the extraBall flag
        STS     extraBall, R16               ;   such that there's no extra ball

        LDI     R16, JOKER_COUNTER_INIT      ; initialize the yellow/green joker
        STS     yellowCounter, R16           ;   counters to start @ the 1st LED
        STS     greenCounter, R16

        RET


; Main() -----------------------------------------------------------------------
; Description:      If a sensor activation is detected, then the sensor code is
;                   retrieved and the appropriate command tables are searched
;                   to determine the functions associated with that sensor.
;
; Operation:        First, Main() determines if a debounced sensor activation
; 	            has been detected. If so, the sensor code is retrieved. If a
;                   game is currently ongoing, then the game command table will 
;                   be searched. Otherwise, the menu command table will be sear-
;                   ched for this sensor code. The appropriate function corresp-
;                   -onding to the sensor code in the table will be called. 
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  currentlyPlaying - flag indicating if game is ongoing [RD]
; 		     sensorCode - code for debounced sensor activation [WR]
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        Table lookup. 
; Data Structures:   GameCmdTable: a table of functions to call based on the
; 				   sensor that has been activated during a game.
;                    MenuCmdTable: a table of functions to call based on the
;                                  sensor that has been activated when a game is 
;                                  currently NOT active.
;
; Registers Changed: R16, R17, R18, R19, R25, Z (ZH | ZL). 
;
; Author:            Emily Wu
; Last Modified:     6/13/2026--------------------------------------------------

Main:
        RCALL   ActuatorHandler            ; every time main is called, the han-
        RCALL   BallCavityHandler          ; -dlers for the actuators, ball cav-
        RCALL   MusicHandler               ; -ity, and music are called. 

        RCALL   HaveSensor                 ; check for a sensor activation
        BREQ    MainDone                   ; if there is none, done.
        ;BRNE   Main_GetSensor             ; otherwise, get the sensor code

Main_GetSensor:
        RCALL   GetSensor                  ; get the sensor code 
        STS     sensorCode, R16            ; put sensor code in shared variable
        LDS     R17, currentlyPlaying      ; get the flag
        TST     R17                        ; check if we're currently playing
        BREQ    MainMenuTable              ; if we are not, go to the menu table
        ;BRNE   GameTable                  ; otherwise go to the game table

MainGameTable:
        LDI     ZH, HIGH(2*GameCmdTable)   ; get start of table for game cmds
        LDI     ZL, LOW(2*GameCmdTable)    ;    (when currently playing)
        LDI     R18, GAME_CMD_COUNT        ; get num entries in the game table
        RJMP    MainSearchLoop

MainMenuTable:
        LDI     ZH, HIGH(2*MenuCmdTable)   ; get start of table for menu cmds
        LDI     ZL, LOW(2*MenuCmdTable)    ;    (when not currently playing)
        LDI     R18, MENU_CMD_COUNT        ; get num entries in the menu table

MainSearchLoop:
        LPM     R17, Z+                    ; get next sensor code from table
        CP      R16, R17                   ; compare passed value with table
        BREQ    MainFound                  ; if found, proceed
        ;BRNE   MainSearch                 ; otherwise, keep searching

MainSearch:
        ADIW    ZL, CMD_ENTRY_SIZE-1       ; skip remaining table entry btyes
        DEC     R18                        ; decrement entry counter
        BRNE    MainSearchLoop             ; go back to loop to keep searching
        ;BREQ   Main_NoMatch               ; no match if we're at the end of the
                                           ;    table. 
Main_NoMatch:
        RJMP    MainDone                   ; if no entries match, we're done

MainFound:
        LPM     R18, Z+                    ; get low byte of function address
        LPM     R19, Z+                    ; get high byte of function address
        LPM     R25,  Z+                   ; get associated argument for func
        MOVW    ZL, R18                    ; move func address into Z pointer
        ICALL                              ; call function at that address
        RJMP    MainDone                   ; done

MainDone:
        RET

; UpdatePlayerRound() ----------------------------------------------------------
; Description:       The current player and round are updated. The extra ball 
;                    functionality is implemented. Extra balls are awarded
;                    immediately after a player has earned one. 
;
; Operation:         If the current player gets an extra ball, then neither the
; 		     current player nor the round are updated because the player
; 		     receives another turn immediately. 
; 		     Otherwise, if the current player is the last player for
; 		     the current round, then the round is incremented and the 
; 		     current player status is transferred to player #1. If 
; 		     the current player is not the last, the current player inc-
;		     -rements. A new round is then initialized in this case. 
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  extraBall     - flag: player gets extra ball [RD/WR]
; 		     currentPlayer - player currently active [1-4] [RD/WR]
; 		     numPlayers    - num total players for this game [1-4] [RD]
; 		     currentRound  - current round [1-5] [WR]
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: R16, R17, R18. 
;
; Author:            Emily Wu
; Last Modified:     6/13/2026--------------------------------------------------

UpdatePlayerRound:
        LDS     R16, extraBall              ; get state of the extraBall flag
        TST     R16                         ; see if the flag is 0
        BREQ    UPR_NoExtra                 ; if not, then no extra ball
        ;BRNE   UPR_Extra                   ; otherwise there's an extra ball

UPR_Extra:                                  ; if there is an extra ball
        LDI     R16, NO_EXTRA_BALL          ; reset extraBall flag
        STS     extraBall, R16              
        RJMP    UPR_InitRound               ; initialize round without updating
                                            ;   the player number/round bc extra
                                            ;   ball is immediately awarded
UPR_NoExtra:
        LDS     R16, currentPlayer          ; get the current player
        LDS     R17, numPlayers             ; get the selected number of players
        CP      R16, R17                    ; check if on last player in round
        BRNE    UPR_NextPlayer              ;   if not, increment player
        ;BREQ   UPR_NextRound               ; otherwise, increment the round

UPR_NextRound:
        LDS     R16, currentRound           ; get current round
        INC     R16                         ; move onto the next round
        STS     currentRound, R16
        CPI     R16, MAX_ROUNDS + 1         ; check if round exceeds max rounds
        BRLO    UPR_ResetPlayer             ; if not, reset back to 1st player
        ;BRSH   UPR_EndGame                 ; if exceeded, end the game

UPR_EndGame:
        LDI     R16, PLAYING_FALSE          ; set state to not currently playing
        STS     currentlyPlaying, R16
        RCALL   EndGame                     ; end the game
        RJMP    UPR_Ret                     ; return

UPR_ResetPlayer:
        LDI     R16, FIRST_PLAYER           ; reset currentPlayer to 1st player
        STS     currentPlayer, R16
        RJMP    UPR_InitRound               ; initialize a new round

UPR_NextPlayer:
        LDS     R16, currentPlayer          ; get current player number
        INC     R16                         ; increment to the next player
        STS     currentPlayer, R16

UPR_InitRound:
        RCALL   InitRound                   ; initialize a new round

UPR_Ret:
        RET


; EndGame() --------------------------------------------------------------------
; Description:       When the game ends, LEDs, music, and the high score are ha-
;                    -ndled. 
;
; Operation:         The display lights are cleared and only the GameOver light 
;                    is lit. The high score is calculated and displayed. If it
;                    is a new high score, music is played. Otherwise, the funct-
;                    -ion returns.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  newHighScoreSet - indicates if new high score was set [RD]
;                    
;
; Input:             None.
; Output:            Displays high score on the first hex display.
;                    Plays music when a new high score is set. 
;                    Lights up the GameOver LED. 
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: R16, R17, R18, R19, R23. 
;
; Author:            Emily Wu
; Last Modified:     06/14/2026-------------------------------------------------


EndGame:
        RCALL   ClearDisplay            ; clear all displays

        LDI     R17, LIGHT_ON           ; display the GameOver LED as on                      
        LDI     R16, GameOver           
        RCALL   DisplayLight

        RCALL  SetHighScore             ; calculate the high score
        LDS     R17, highScore          ; get the high score
        LDS     R16, highScore+1

        RCALL   Bin2BCD                 ; convert high score from binary -> BCD

        MOV     R17, R19                ; move BCD result in R19:R18 to R17:R16
        MOV     R16, R18                ;       which is used by DisplayHex

        LDI     R18, FIRST_PLAYER       ; get the first player
        RCALL   DisplayHex              ; display score on 1st player's display

        LDS     R23, newHighScoreSet    ; get the high score flag 
        TST     R23                     ; determine if the high score is new 
        BREQ    EndGameDone             ; if it is an old high score, done
        ;BRNE   PlayHighScoreMusic      ; otherwise, play high score music

PlayHighScoreMusic:
        RCALL   PlaySuccess             ; play success tune

EndGameDone:
        RET

; PlaySuccess ------------------------------------------------------------------
; Description:       Plays a short melody for a specified number of loops.  
;
; Operation:         Loops through a table of frequencies and plays the notes. 
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  None.             
;
; Input:             None.
; Output:            Plays sound. 
;
; Error Handling:    None.
;
; Algorithms:        Table lookup. 
; Data Structures:   A table containing the frequencies of notes to play. 
;
; Registers Changed: R0, R16, R17, R20, R21, Z (ZH | ZL), X (XH | XL). 
;
; Special Notes:     This is a blocking function, but it is acceptable because
;                    it only is used at the end of a game. Players must wait for 
;                    the music to finish before starting a new game.
; 
; Author:            Emily Wu
; Last Modified:     06/14/2026-------------------------------------------------

PlaySuccess:
        LDI     R21, NUM_LOOPS              ; get number of times to loop

PS_LoopOuter:
        LDI     ZL,LOW(2*SuccessTab)        ; get start of table
        LDI     ZH,HIGH(2*SuccessTab)
        LDI     R20,SuccessTab_LEN          ; get number of notes in the tune

PS_Loop:
        LPM     R16,Z+                      ; get frequency of next note (low)
        LPM     R17,Z+                      ; freq of next note (high)
        PUSH    ZL                          ; preserve registers
        PUSH    ZH
        PUSH    R20
        PUSH    R21
        RCALL   PlayNote                    ; play the frequency
        LDI     R16, SUCCESS_TIMER          ; get delay timer number
        LDI     XL,LOW(SUCCESS_NOTE_LEN)    ; get length of each note
        LDI     XH,HIGH(SUCCESS_NOTE_LEN)
        RCALL   StartDelay                  ; delay for length of note

PS_Wait:
        LDI     R16,SUCCESS_TIMER           ; get timer number again
        RCALL   DelayNotDone                ; check if started delay is done
        TST     R0                          ; R0 low indicates timer done
        BRNE    PS_Wait                     ; if high, keep waiting                   
        ;BREQ   PS_Continue                 ; if low, move onto next note

PS_Continue:
        POP     R21                         ; restore registers
        POP     R20
        POP     ZH
        POP     ZL
        DEC     R20                         ; decrement note counter
        BRNE    PS_Loop                     ; if haven't reached last note, loop
        ;BREQ   PS_Replay                   ; if we have, replay the melody

PS_Replay:
        DEC     R21                         ; decrement loop counter 
        BRNE    PS_LoopOuter                ; if we aren't done looping, replay
        ;BREQ   PS_Done                     ; otherwise, finish. 

PS_Done:
        RET

; UpdateScore(points) ----------------------------------------------------------
; Description:      For most pinball sensor activations, points are awarded whe-
;                   the game is currently active.  
;                   The current score buffer is retreived and added to in order
;                   calculate and display the updated score. 
;
; Operation:        Arithmetic is performed on the current player number in
;                   order to obtain the correct byte address in the currentScore
;                   buffer containing the current player's score. The requisite
;                   number of points based on the sensor activation are added
;                   to the player's allocated 2 bytes in the buffer. The new
;                   score is then displayed on the hex display for the player. 
;
; Arguments:         points - number of points to add to the current score [R25] 
; Return Value:      None.
;
; Local Variables:   None.  
; Shared Variables:  currentScores - buffer containing all player's scores for 
;                                    a single game [RD/WR]
;                    currentPlayer - player currently active [1-4] [RD]
;
; Input:             None.
; Output:            Displays updated score on the current player's hex display.
;
; Error Handling:    If the updated score exceeds MAX_SCORE, the score saturates
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: R16, R17, R18, R19, R20, R21, R22, Y (YH|YL). 
;
; Author:            Emily Wu
; Last Modified:     6/13/2026--------------------------------------------------

UpdateScore:
        MOV     R22, R25                      ; preserve point value
        LDS     R18, currentPlayer            ; get currently active player
        MOV     R20, R18                      ; move player number to new reg
        DEC     R20                           ; calculate byte address
        LSL     R20                           ;    address=(player-1)*2

        LDI     YL, LOW(currentScores)        ; get current score buffer
        LDI     YH, HIGH(currentScores)
        CLR     R21
        ADD     YL, R20                       ; go to byte address for this 
        ADC     YH, R21                       ;     player in the buffer

        LD      R17, Y+                       ; get this player's score (high)
        LD      R16, Y                        ; get this player's score (low)
        ADD     R16, R22                      ; add points to player's score
        ADC     R17, R21                      ; propagate carry

        CPI     R17, HIGH(MAX_SCORE+1)        ; check if high byte exceeds max
        BRLO    US_Store                      ; if not exceeding, store score
        ;BRSH   US_ContinueCheckMax           ; otherwise, check the low byte

US_ContinueCheckMax:
        BRNE    US_Saturate                   ; score definitely exceeds max
        ;BREQ   US_CheckLowByte               ; if not, check low byte

US_CheckLowByte:
        CPI     R16, LOW(MAX_SCORE+1)         ; check if low byte exceeds max
        BRSH    US_Saturate                   ; if exceeding, saturate @ the max
        ;BRLO   US_Store

US_Store:
        SBIW    Y, BACK_TO_START              ; move Y pointer back to start
        ST      Y+, R17                       ; store high byte
        ST      Y,  R16                       ; store low byte
        RJMP    US_Display

US_Saturate:
        LDI     R17, HIGH(MAX_SCORE)          ; saturate to the maximum value
        LDI     R16, LOW(MAX_SCORE)
        SBIW    Y, BACK_TO_START              ; go back to start of score
        ST      Y+, R17                       ; store saturated score value
        ST      Y,  R16

US_Display:
        RCALL   Bin2BCD                       ; convert bin score for DisplayHex
        MOV     R16, R18                      ; DisplayHex gets value in R17:R16
        MOV     R17, R19                      
        LDS     R18, currentPlayer            ; get player to display for
        RCALL   DisplayHex                    ; display their score
        RET

; YellowGreenChange() ----------------------------------------------------------
; Description:      +YG_CHANGE_PTS; unbounded per round. 
;                   When struck, the corresponding color LEDs for "300 points
;                   when lit and "Increases value when lit" are activated in
;                   unison, i.e. if either the upper or lower "Green Change" 
;                   sensors are struck, the two yellow LEDs will deactivate and
;                   two green ones will activate.
;
; Operation:         UpdateScore is called to increment the score by 
;                    YG_CHANGE_PTS. The sensor is checked for whether it was 
;                    green or yellow. Both of the same-color LEDs are turned on, 
;                    while both of the LEDs of the other color are turned off. 
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  sensorCode - code for debounced sensor activation [RD]
;
; Input:             None.
; Output:            LEDs are turned on and off, depending on the sensor code. 
;                    The score display is updated for the current player. 
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: R25, R16, R17. 
;
; Author:            Emily Wu
; Last Modified:     6/14/2026--------------------------------------------------

YellowGreenChange:
        LDI     R25, YG_CHANGE_PTS         ; get amount of points to add
        RCALL   UpdateScore                ; update and display score
        LDS     R16, sensorCode            ; get sensor code
        CPI     R16, LowerYellowChange     ; check which of the 4 sensors it is
        BREQ    SetYellowState             ; go to label corresp. w/ the sensor
        ;BRNE   CheckUpperYellow           ; keep checking until it matches

CheckUpperYellow:
        CPI     R16, UpperYellowChange     ; check if it's upper yellow sensor
        BREQ    SetYellowState             ; if so, branch to yellow label
        ;BRNE   SetGreenState              ; if not, it must be green

SetGreenState:
        LDI     R17, LIGHT_OFF             ; set light state to off
        LDI     R16, YPoints300                 
        RCALL   DisplayLight               ; turn YPoints300 LED off
        LDI     R16, IncreasesValY
        RCALL   DisplayLight               ; turn IncreasesValY LED off

        LDI     R17, LIGHT_ON              ; set light state to on
        LDI     R16, GPoints300
        RCALL   DisplayLight               ; turn GPoints300 LED on
        LDI     R16, IncreasesValG
        RCALL   DisplayLight               ; turn IncreasesValG LED on
        RET

SetYellowState:
        LDI     R17, LIGHT_OFF             ; set light state to off
        LDI     R16, GPoints300
        RCALL   DisplayLight               ; turn GPoints300 LED off
        LDI     R16, IncreasesValG
        RCALL   DisplayLight               ; turn IncreasesValG LED off

        LDI     R17, LIGHT_ON              ; set light state to on
        LDI     R16, YPoints300
        RCALL   DisplayLight               ; turn YPoints300 LED on
        LDI     R16, IncreasesValY
        RCALL   DisplayLight               ; turn IncreasesValY LED on
        RET

; AcesKings(l) -----------------------------------------------------------------
; Description:       +ACES_KINGS_PTS points each.
;                    When struck, the associated LED will deactivate and remain 
;                    deactivated for the remainder of the round. 
;                    If all LEDs are deactivated on a given side, the 
;                    corresponding ""Extra ball when lit"" LED will activate 
;                    Kings correspond to right LED, Aces correspond to left LED. 
;
; Operation:         ACES_KINGS_PTS are awarded (once per round per sensor). The 
;                    LED corresponding to the debounced activated sensor is ens-
;                    -ured to be off. If all LEDs for the king side or ace side
;                    are off, respectively, then the Extra Ball LED for that
;                    side is turned on and the player receives an extra ball.
;
; Arguments:         l - light number of an LED (0-127). 
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  extraBall - flag: current player gets 1 extra ball [WR]
;                    currentRows - buffer holds current displayed row patts [RD]
;
; Input:             None.
; Output:            Turns Aces/Kings LEDs off when hit, updates score, and 
;                    turns on extra ball LEDs if all Aces or all Kings are off.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: R16, R17, R18, R19, R21, R22, R23, R25, Z (ZH|ZL). 
;
; Special Notes:     A player may receive a maximum of 1 extra ball per round.
;                    The extra ball/round goes into effect immediately, i.e. the 
;                    player who has earned it will play 2 rounds in a row. 
;
; Author:            Emily Wu
; Last Modified:     6/14/2026--------------------------------------------------

AcesKings:
        MOV     R18, R25                  ; preserve light number l
        MOV     R19, R18
        LSR     R19                       ; calculate row by doing l//8
        LSR     R19
        LSR     R19
        ANDI    R18, MOD_FACTOR           ; init col ctr by doing l % 8

        LDI     ZL, LOW(currentRows)      ; get current score buffer 
        LDI     ZH, HIGH(currentRows)
        CLR     R21
        ADD     ZL, R19                   ; go to the calculated row in buffer
        ADC     ZH, R21                   ; carry propagation
        LD      R22, Z                    ; get pattern at this row
        LDI     R23, INIT_MASK            ; set up initial column mask

AKMaskLoop:
        CPI     R18, 0                    ; keep shifting mask until col ctr = 0
        BREQ    AKMaskDone                ; if ctr = 0, mask is complete
        ;BRNE   AKMaskLoopCont            ; otherwise keep building mask

AKMaskLoopCont:
        LSL     R23                       ; left shift the mask 
        DEC     R18                       ; decrement the col ctr
        RJMP    AKMaskLoop                ; keep looping

AKMaskDone:
        AND     R22,R23                  ; obtain the LED at the correct row/col
        BREQ    AcesKingsDone            ; if this LED is off, then no updates
        ;BRNE   AcesKingsUpdate          ; if the LED is on, continue to updates

AcesKingsUpdate:
        PUSH    R25                       ; preserve light num
        LDI     R25, ACES_KINGS_PTS       ; get point value
        RCALL   UpdateScore               ; update score display
        POP     R25                       ; restore light num

        MOV     R16,R25                   ; feed light number to DisplayLight 
        LDI     R17, LIGHT_OFF            ; turn this light off
        RCALL   DisplayLight

CheckKingsAllOff:
        LDS     R18,currentRows+KH_ROW    ; check buffer value at the precalcul-
        ANDI    R18,KH_MASK               ; -ated row and column for all of the 
        LDS     R19,currentRows+KD_ROW    ; kings   
        ANDI    R19,KD_MASK              
        OR      R18,R19                   ; if at least one is not off, the OR       
        LDS     R19,currentRows+KC_ROW    ;    will yield a nonzero value
        ANDI    R19,KC_MASK
        OR      R18,R19
        LDS     R19,currentRows+KS_ROW
        ANDI    R19,KS_MASK
        OR      R18,R19
        BRNE    CheckAcesAllOff           ; if any king is lit, check aces
        ;BREQ   AK_ExtraBallR             ; if all kings off, then extra ball

AK_ExtraBallR:
        LDI     R16, ExtraBallR           ; get light num for extra ball LED (R)
        LDI     R17, LIGHT_ON             ; turn extra ball LED on
        RCALL   DisplayLight 
        LDI     R16, EXTRA_BALL_TRUE      ; update the extra ball flag
        STS     extraBall,R16

CheckAcesAllOff:
        LDS     R18,currentRows+AH_ROW    ; check buffer value at the precalcul-
        ANDI    R18,AH_MASK               ; -ated row and column for all of the 
        LDS     R19,currentRows+AD_ROW    ; aces
        ANDI    R19,AD_MASK
        OR      R18,R19                   ; if at least one is not off, the OR
        LDS     R19,currentRows+AC_ROW    ;    will yield a nonzero value
        ANDI    R19,AC_MASK
        OR      R18,R19
        LDS     R19,currentRows+AS_ROW
        ANDI    R19,AS_MASK
        OR      R18,R19
        BRNE    AcesKingsDone           ; if any aces is lit, done
        ;BREQ   AK_ExtraBallL           ; if all aces off, then extra ball

AK_ExtraBallL:
        LDI     R16, ExtraBallL         ; get light num for extra ball LED (L)
        LDI     R17, LIGHT_ON           ; trn extra ball LED on
        RCALL   DisplayLight
        LDI     R16, EXTRA_BALL_TRUE    ; update the extra ball flag
        STS     extraBall,R16

AcesKingsDone:
        RET

; RedGreenYellow() -------------------------------------------------------------
; Description:      +RGY_PTS points every sensor hit (unbounded per round).
;                   The green and yellow LEDs are lit when they are hit for the
;                   first time in a round and remain lit for the remainder of 
;                   the round. The red LED is always on. When one is hit, its 
;                   associated actuator also turns on (and then off soon after). 
;
; Operation:         The score is updated via UpdateScore. The sensor color is
;                    checked: if yellow, the yellow LED is turned on. If green,
;                    the green LED is turned on. The corresp actuator activates.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  sensorCode - code for debounced sensor activation [RD]
;
; Input:             None.
; Output:            Activates actuators, updates scores, and lights LEDs. 
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: R16, R17, R25. 
;
; Author:            Emily Wu
; Last Modified:     6/14/2026--------------------------------------------------

RedGreenYellow:
        LDI     R25, RGY_PTS              ; get points to add
        RCALL   UpdateScore               ; update the score/display
        LDS     R16, sensorCode           ; obtain code for hit sensor

RGY_CheckYellow:
        CPI     R16,Yellow                ; check if code is yellow sensor
        BRNE    RGY_CheckGreen            ; if not, check if green
        ;BREQ   RGY_Yellow
RGY_Yellow:
        PUSH    R16                       ; preserve register
        LDI     R16,YellowLED             ; get yellow LED light num
        LDI     R17,LIGHT_ON              ; turn yellow LED on
        RCALL   DisplayLight
        POP     R16                       ; restore register
        LDI     R16,YellowAct             ; get yellow actuator number
        RCALL   ActuatorTurnOn            ; pulse yellow actuator        
        RJMP    RGYDone

RGY_CheckGreen:
        CPI     R16,Green                 ; check if code is green sensor
        BRNE    RGY_CheckRed              ; if not, check if red
        ;BREQ   RGY_Green
RGY_Green:
        PUSH    R16                       ; preserve register
        LDI     R16,GreenLED              ; get green LED light num
        LDI     R17,LIGHT_ON              ; turn green LED on
        RCALL   DisplayLight
        POP     R16                       ; restore register
        LDI     R16,GreenAct              ; get green actuator number    
        RCALL   ActuatorTurnOn            ; pulse green actuator
        RJMP    RGYDone

RGY_CheckRed:
        CPI     R16,Red                   ; check if code is red sensor
        BRNE    RGYDone                   ; if not, then done
        ;BREQ   RGY_Red
RGY_Red:
        LDI     R16,RedAct                ; get red actuator number
        RCALL   ActuatorTurnOn            ; pulse red actuator

RGYDone:
        RET

; WheelHit() -------------------------------------------------------------------
; Description:       After the wheel is struck, the currently lit Joker 
;                    "10-100 line" (yellow or green) as indicated by the 
;                    "Increases value when lit" LED will light up one more LED. 
;                    The total point range is from 10 to 100 in 10-point 
;                    increments. These points are not cached automatically - see
;                    BallCavity(). 
;
; Operation:         The "Increases value when lit" LED that is on determines
;                    whether the green or yellow joker LED line is acted upon. 
;                    The line on the same side will light up one more light, 
;                    or remain in the same state if all lights are already lit. 
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  currentRows - buffer holds current displayed row patts [RD]
;                    yellowCounter - cntr for 10-100 LEDs: yellow joker [RD/WR]
;                    greenCounter - cntr for 10-100 LEDs: green joker [RD/WR]
;
; Input:             None.
; Output:            Lights up LEDs on the joker lines. 
;
; Error Handling:    If all 10 lights on a given side are lit, nothing occurs. 
;
; Algorithms:        Table lookup. 
; Data Structures:   Tables relating the light numbers for the 10-100 LEDs to  
;                    their numerical value for both yellow/green joker. 
;
; Registers Changed: R0, R16, R17, Z (ZH|ZL). 
;
; Author:            Emily Wu
; Last Modified:     6/14/2026--------------------------------------------------

WheelHit:
        LDS     R16, currentRows+INC_Y_ROW ; load row containing IncreaseValY
        ANDI    R16, INC_Y_MASK            ; isolate IncreaseValY bit
        BREQ    Wheel_Green                ; if it isn't lit, then go to green
        ;BRNE   Wheel_Yellow               ; if it is lit, go to yellow

Wheel_Yellow:
        LDS     R17, yellowCounter         ; get ctr for current place on line
        CPI     R17, JOKER_MAX             ; check if we're at the last LED
        BRSH    Wheel_Green                ; if we are, then branch to green
        ;BRLO   Wheel_YellowInc            ; otherwise increment yellow
Wheel_YellowInc:
        INC     R17                        ; yellowCounter++
        STS     yellowCounter, R17
        DEC     R17                        ; table index = yellowCounter-1
        LDI     ZH, HIGH(2*JokerTableY)    ; get start of table
        LDI     ZL, LOW(2*JokerTableY)
        ADD     ZL, R17                    ; go to current LED's location
        CLR     R0                         ; zero R0 for carry propagation
        ADC     ZH, R0

        LPM     R16, Z                     ; load light number for this LED
        LDI     R17, LIGHT_ON              ; turn the LED w/ that light num on
        PUSH    ZH                         ; preserve Z reg
        PUSH    ZL
        RCALL   DisplayLight
        POP     ZL
        POP     ZH

Wheel_Green:
        LDS     R16, currentRows+INC_G_ROW ; load row containing IncreaseValG
        ANDI    R16, INC_G_MASK            ; isolate IncreaseValG bit
        BREQ    WheelDone                  ; if it isn't lit, then done
        ;BRNE   Wheel_GreenCheck           ; if it is lit, then proceed
Wheel_GreenCheck:
        LDS     R17, greenCounter          ; get ctr for current place on line
        CPI     R17, JOKER_MAX             ; check if we're at the last LED
        BRSH    WheelDone                  ; if we are, then branch to end
        ;BRLO   Wheel_GreenInc
Wheel_GreenInc:
        INC     R17                        ; greenCounter++
        STS     greenCounter, R17
        DEC     R17                        ; table index = greenCounter-1
        LDI     ZH, HIGH(2*JokerTableG)    ; get start of table
        LDI     ZL, LOW(2*JokerTableG)
        ADD     ZL, R17                    ; go to current LED's location
        CLR     R0                         ; zero R0 for carry propagation
        ADC     ZH, R0

        LPM     R16, Z                     ; load light number for this LED
        LDI     R17, LIGHT_ON              ; turn the LED w/ that light num on
        PUSH    ZH                         ; preserve Z register
        PUSH    ZL
        RCALL   DisplayLight
        POP     ZL
        POP     ZH

WheelDone:
        RET

; ActuatorTurnOn(n) ------------------------------------------------------------
; Description:       Turns on an actuator for the length of ACTUATOR_DELAY. 
;
; Operation:         Turn on the desired actuator and begin the delay time ctr. 
;
; Arguments:         n - actuator number between 0 and 7 to activate [R16]. 
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  None.
;
; Input:             None.
; Output:            Activates an actuator. 
;
; Error Handling:    None. 
;
; Algorithms:        None.  
; Data Structures:   None. 
;
; Registers Changed: R17, X (XH|XL). 
;
; Author:            Emily Wu
; Last Modified:     6/14/2026--------------------------------------------------

ActuatorTurnOn:

        PUSH    R16                     ; preserve register      
        LDI     R17, ACTUATOR_ON        ; we want the actuator to be active
        RCALL   SetActuator             ; set the desired actuator
        POP     R16                     
        LDI     XL,LOW(ACTUATOR_DELAY)  ; load delay time for actuator
        LDI     XH,HIGH(ACTUATOR_DELAY)

        RCALL   StartDelay              ; begin counting the delay

        RET

; ActuatorHandler() ------------------------------------------------------------
; Description:       Checks if a delay is done, and if so, turns actuators off. 
;
; Operation:         Checks all actuator timers. If the timer has been used up, 
;                    then the associated actuator is turned off. Otherwise, no-
;                    -thing is done. 
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  None.
;
; Input:             None.
; Output:            Actuators will be turned off if their timers run up. 
;
; Error Handling:    None. 
;
; Algorithms:        None. 
; Data Structures:   None. 
;
; Registers Changed: X (XH|XL), R0, R16, R17, R18. 
;
; Author:            Emily Wu
; Last Modified:     6/14/2026--------------------------------------------------

ActuatorHandler:
        CLR     R18                     ; begin with actuator timer 0

AH_Loop:
        MOV     R16,R18                 ; move to reg expected by DelayNotDone
        RCALL   DelayNotDone            ; check if the timer has finished
        TST     R0                      ; R0 high means timer is running
        BRNE    AH_Next                 ; timer still running
        ;BREQ   AH_TurnOff              ; R0 low means timer is done

AH_TurnOff:
        MOV     R16,R18                 ; SetActuator needs actuator num in R18
        LDI     R17, ACTUATOR_OFF       ; want actuator to be off
        RCALL   SetActuator             ; set this actuator to be off

AH_Next:
        INC     R18                     ; move onto next actuator/timer
        CPI     R18, NUM_ACTUATORS      ; check if we've reached last actuator
        BRLO    AH_Loop                 ; if not, continue looping
        ;BRSH   AH_Done                 ; if so, all actuators accounted for

AH_Done:
        RET 

; BallCavity() -----------------------------------------------------------------
; Description:       When the ball lands in a ball cavity, the corresponding 
;                    Joker LED line on the same side as the cavity (left/right) 
;                    will be acted on, regardless of which side is currently 
;                    active according to the ""Increases value when lit"" LED.
;                    All previously accumulated points on this LED line will be 
;                    added to the score. 
;                    The cavity mechanism will hold the ball in place until the 
;                    score has been fully updated. After this point, it will 
;                    project the ball out of the cavity, and the LEDs will 
;                    sequentially turn off from highest to lowest until all are 
;                    off on that side. 
;
; Operation:         It is determined whether the left or right cavity recieved 
;                    the ball. The points accumulated, as determined by the num-
;                    -ber of lit LEDs on the left or right side, respectively, 
;                    are cached and the ball is released. Sequentially, the
;                    lights are turned off from the highest value to the lowest
;                    on the side where the cavity received a ball. 
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  sensorCode - code for most recently debounced sensor activ.
;                    yellowCounter - counter for 10-100 LED line (yellow joker)
;                    greenCounter - counter for 10-100 LED line (green joker)
;
; Input:             None.
; Output:            Sets hex display with updated score; activates actuator.
;
; Error Handling:    None.
;
; Algorithms:        None. 
; Data Structures:   None. 
;
; Registers Changed: R0, R1, R16, R25, X (XH|XL). 
;
; Author:            Emily Wu
; Last Modified:     6/14/2026--------------------------------------------------

BallCavity:
        LDS     R16,sensorCode             ; get sensorCode
        CPI     R16,BallCavityL            ; if the ball hit the left side,
        BREQ    BC_LeftGreen               ;    proceed to left/green actions
        ;BRNE   BC_RightYellow             ; otherwise the ball hit the right

BC_RightYellow:
        LDS     R25,yellowCounter          ; get yellow ctr value
        LDI     R16,JOKER_LINE_PTS         ; load in point value
        MUL     R25,R16                    ; pts = yellowCounter*JOKER_LINE_PTS
        MOV     R25,R0                     ; place pts in R25 for UpdateScore
        CLR     R1
        RCALL   UpdateScore                ; update score w/ calculated points

        LDI     R16,BallCavityRActuator    ; get right ball cavity actuator num
        RCALL   ActuatorTurnOn             ; activate the actuator
        LDS     R16,yellowCounter          ; store yellowCounter in the counter
        STS     cavityCount,R16            ;    indicating num remaining LEDs

        LDI     R16, RIGHT_SIDE            ; update the cavity side variable
        STS     cavitySide,R16
        LDI     R16, ACTUATOR_ON           ; indicate actuator is active
        STS     cavityActive,R16

        LDI     R16,CAVITY_TIMER           ; setup actuator timer
        LDI     XL,LOW(CAVITY_DELAY)       ; load in time for cavity actuator
        LDI     XH,HIGH(CAVITY_DELAY)
        RCALL   StartDelay                 ; begin counting delay
        RET

BC_LeftGreen:
        LDS     R25,greenCounter           ; get green ctr value
        LDI     R16,JOKER_LINE_PTS         ; load in point value
        MUL     R25,R16                    ; pts = greenCounter*JOKER_LINE_PTS
        MOV     R25,R0                     ; place pts in R25 for UpdateScore
        CLR     R1
        RCALL   UpdateScore                ; update score w/ calculated points

        LDI     R16,BallCavityLActuator    ; get left ball cavity actuator num
        RCALL   ActuatorTurnOn             ; activate the actuator
        LDS     R16,greenCounter           ; store greenCounter in the counter
        STS     cavityCount,R16            ;    indicating num remaining LEDs

        LDI     R16, LEFT_SIDE             ; update the cavity side variable
        STS     cavitySide,R16
        LDI     R16, ACTUATOR_ON           ; indicate actuator is active
        STS     cavityActive,R16

        LDI     R16,CAVITY_TIMER           ; setup actuator timer
        LDI     XL,LOW(CAVITY_DELAY)       ; load in time for cavity actuator
        LDI     XH,HIGH(CAVITY_DELAY)
        RCALL   StartDelay                 ; begin counting delay

        RET

; BallCavityHandler() ----------------------------------------------------------
; Description:       Deactivates LEDs when a ball goes into a cavity.
;
; Operation:         Check if the cavity sequence is active or not. If active, 
;                    wait for the cavity actuator timer to finish before beginn-
;                    -ing. The cavity LED counter is decremented and indexes th-
;                    -rough the green/yellow joker light number tables (as dete-
;                    -ermined by cavitySide). The LEDs are turned off one by one
;                    and are spaced out by a specified delay time.
;                    Once complete, the cavity active flag is set low. 
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  cavityCount - LEDs remaining for a joker line [RD/WR]
;                    cavityActive - flag for if cavity sequence active [RD/WR]
;                    cavitySide  - the currently active joker side [RD]
;
; Input:             None.
; Output:            displays LED lights on the joker lines. 
;
; Error Handling:    None.
;
; Algorithms:        Table Lookup. 
; Data Structures:   Tables with the constants that hold the light numbers for 
;                    the yellow and green joker lines. 
;
; Registers Changed: R0, R1, R16, R17, R18, R19, R20, X (XH|XL). 
;
; Author:            Emily Wu
; Last Modified:     6/14/2026--------------------------------------------------
BallCavityHandler:
        LDS     R16,cavityActive           ; check if cavity should be active
        TST     R16                         
        BREQ    BCH_Done                   ; if not, done
        ;BRNE   BCH_CavityTimer            ; otherwise continue

BCH_CavityTimer:
        LDI     R16,CAVITY_TIMER           ; load cavity timer number
        RCALL   DelayNotDone               ; check if delay timer is done
        TST     R0                         
        BRNE    BCH_Done                   ; timer still running
        ;BREQ   BCH_NextLED                

BCH_NextLED:
        LDS     R18,cavityCount            ; get num LEDs remaining to clear
        TST     R18                        ; check if done turning all LEDs off
        BREQ    BCH_Finished               ; if so, done
        ;BRNE   BCH_SelectColor

BCH_SelectColor:
        DEC     R18                        ; convert LED count to table index
        LDS     R19,cavitySide             ; determine if right or left active
        TST     R19                        ; 0 = green, 1 = yellow
        BRNE    BCH_Yellow                 ; go to active side
        ;BREQ   BCH_Green                   

BCH_Green:
        LDI     ZL,LOW(2*JokerTableG)      ; get start of table (green)
        LDI     ZH,HIGH(2*JokerTableG)
        STS     greenCounter,R18           ; update LED counter for new position
        RJMP    BCH_ProcessLED             ; go to table logic

BCH_Yellow:
        LDI     ZL,LOW(2*JokerTableY)      ; get start of table (yellow)
        LDI     ZH,HIGH(2*JokerTableY)
        STS     yellowCounter,R18          ; update LED counter for new position

BCH_ProcessLED:
        ADD     ZL,R18                     ; go to appropriate table index                   
        CLR     R20                        ; clear for carry propagation
        ADC     ZH,R20
        LPM     R16,Z                      ; get light number from table
        LDI     R17, LIGHT_OFF             ; turn this light off
        RCALL   DisplayLight

BCH_RestartTimer:
        STS     cavityCount,R18            ; save remaining LED count
        LDI     R16,CAVITY_TIMER           ; get timer number again
        LDI     XL,LOW(CAVITY_DELAY)       ; set delay time
        LDI     XH,HIGH(CAVITY_DELAY)
        RCALL   StartDelay                 ; begin delay
        RJMP    BCH_Done                   

BCH_Finished: 
        CLR     R16
        STS     cavityActive,R16           ; set cavity as inactive
 
BCH_Done:
        RET

; SetHighScore() ---------------------------------------------------------------
; Description:       After every full game finishes, the highest score from the
;                    game is compared to the overall highest score stored in the
;                    EEROM. If it is higher, the EEROM is written to with the 
;                    new all-time highest score. 
;
; Operation:         The current high score is read from the beginning of the 
;                    EEROM. The currentScores buffer is checked to determine
;                    if any scores from the game were higher than the highScore. 
;                    If so, the EEROM is written to with the new highest score. 
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  currentScores - buffer containing all player's scores for 
;                                    a single game [RD]
;                    highScore - Holds previous high score, and if
;                                a new high score is set, is updated [RD/WR]
;                    newHighScoreSet - indicates if new high score was set [WR]
;
; Input:             None.
; Output:            Writes the EEROM. 
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: R16, R17, R18, R19, R20, R21, R22, R23, Z (ZH|ZL), Y(YH|YL)
;
; Author:            Emily Wu
; Last Modified:     6/14/2026--------------------------------------------------


SetHighScore:
        LDI     R23, NO_NEW_HIGHSCORE                     
        STS     newHighScoreSet, R23    ; initializes the new high score flag 
        LDI     YL, LOW(highScore)      ; get the current all time high score
        LDI     YH, HIGH(highScore)

        LDI     R17, HIGH_SCORE_ADDRESS ; EEROM address holding high score
        LDI     R16, SCORE_BYTE_LEN     ; read bytes of the score
        RCALL   ReadEEROM

SHS_LoadHighScore:
        LDS     R20, highScore          ; high byte of high score
        LDS     R21, highScore+1        ; low byte of high score

SHS_ScanCurrentBuffer:
        LDI     YL, LOW(currentScores)  ; get the current score buffer
        LDI     YH, HIGH(currentScores)
        LDI     R22, MAX_PLAYERS        ; ctr for num of player scores (at max)

SHS_Loop:
        LD      R18, Y+                 ; get specific player's score high byte
        LD      R19, Y+                 ; score low byte
        CP      R19, R21                ; compare this score (R18:R19) to 
        CPC     R18, R20                ;    highScore (R20:R21)
        BRLO    SHS_Next                ; score < all-time highScore
        BREQ    SHS_Next                ; score = all-time highScore
        ;BRSH   SHS_NewHighScore        ; score > all-time highScore

SHS_NewHighScore:
        LDI     R23, NEW_HIGHSCORE      ; record that the high score has been 
        STS     newHighScoreSet, R23    ;     beaten during this game
        MOV     R20, R18                ; new high score (high byte)
        MOV     R21, R19                ; new high score (low byte)

SHS_Next:
        DEC     R22                     ; decrement the player counter
        BRNE    SHS_Loop                ; cont. looping till all players checked
        ;BREQ   SHS_StoreHighScore      ; if done, store high score

SHS_StoreHighScore:
        STS     highScore,   R20        ; put high score high byte in shared var
        STS     highScore+1, R21        ; put high score low byte in shared var
        TST     R23                     ; if not a new high score, then...
        BREQ    SHS_Done                ; ...skip EEROM write
        ;BRNE   SHS_WriteEEROM

SHS_WriteEEROM:
        LDI     YL, LOW(highScore)      ; get shared variable with high score
        LDI     YH, HIGH(highScore)
        LDI     R17, HIGH_SCORE_ADDRESS ; get EEROM address to write at
        LDI     R16, SCORE_BYTE_LEN     ; write bytes of the score
        RCALL   WriteEEROM              

SHS_Done:
        RET


; LitesYellowGreen() -----------------------------------------------------------
; Description:      100 or 300 points.
;                   The ball necessarily rolls over one of the 2 sensors, giving
;                   a minimum of 100 points by default. When the ball rolls over
;                   the sensor with the same color as the currently lit "300 
;                   points when lit" LED, 300 points will be awarded instead.
;                   This also determines which of the Joker LEDs (Green/Yellow 
;                   "10 times value when lit"") remains on for the remainder of
;                   the round."
;
; Operation:         If the sensor was yellow and the yellow 300-point LED was
;                    on, 300 points are awarded and the 10x LED is turned on. 
;                    The same process occurs if the sensor was green and the 
;                    green 300-point LED was on. Otherwise, only 100 points are
;                    awarded. Note that the 10x multiplier will not be actually
;                    implemented. 
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  sensorCode - code for debounced sensor activation [RD]
;                    currentRows - buffer holds current displayed row patts [RD]
;
; Input:             None.
; Output:            Turns the 10x light on if the rollover was the same color 
;                    as the currently lit "300 points when lit" LED.
;                    Updates the current player's score. 
;
; Error Handling:    None.
;
; Algorithms:        None. 
; Data Structures:   None.
;
; Registers Changed: R16, R17, R25
;
; Author:            Emily Wu
; Last Modified:     6/14/2026--------------------------------------------------

LitesYellowGreen:
        LDI     R25, LITES_YG_PTS           ; base points for sensor rollover 
        RCALL   UpdateScore                 ; add base points
        LDS     R16, sensorCode             ; get sensor code

LYG_Yellow:
        CPI     R16, LitesYellowJoker       ; cmpare sensor code to lites yellow
        BRNE    LYG_Green                   ; if not this sensor, move on
        ;BREQ   LYG_YellowCheck
LYG_YellowCheck:
        LDS     R17, currentRows+Y300_ROW  ; go to row of yellow 300 LED
        ANDI    R17, Y300_MASK             ; obtain the LED state w/ a col mask
        BREQ    LYG_Done                   ; if yellow 300 LED isn't lit, done
        ;BRNE   LYG_YellowExtra
LYG_YellowExtra:
        LDI     R25, LITES_YG_EXTRA_PTS    ; +extra points to base points
        RCALL   UpdateScore                ; update player's points
        LDI     R16, YellowJoker10x        ; get light num for yellow joker 10x
        LDI     R17, LIGHT_ON              ; turn the LED on
        RCALL   DisplayLight
        RJMP    LYG_Done

LYG_Green:
        CPI     R16, LitesGreenJoker        ; cmpare sensor code to lites green
        BRNE    LYG_Done                    ; if not this sensor, done
        ;BREQ   LYG_GreenCheck
LYG_GreenCheck:
        LDS     R17, currentRows+G300_ROW   ; go to row of green 300 LED
        ANDI    R17, G300_MASK              ; obtain the LED state w/ a col mask
        BREQ    LYG_Done                    ; if green 300 LED isn't lit, done
        ;BRNE   LYG_GreenExtra
LYG_GreenExtra:
        LDI     R25, LITES_YG_EXTRA_PTS    ; +extra points to base points
        RCALL   UpdateScore                ; update player's points
        LDI     R16, GreenJoker10x         ; get light num for green joker 10x
        LDI     R17, LIGHT_ON              ; turn the LED on
        RCALL   DisplayLight

LYG_Done:
        RET


; StartMusic() -----------------------------------------------------------------
; Description:       Ensures that music starts on the first note. 
;
; Operation:         Update the musicIndex shared variable to start on the 1st 
;                    note.                    
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  musicIndex - current note number [WR]. 
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
; Last Modified:     6/14/2026--------------------------------------------------

StartMusic:
        CLR     R16
        STS     musicIndex,R16                  ; start at zeroth index

        RET

; MusicHandler() ---------------------------------------------------------------
; Description:      Plays background music continuously while a game is ongoing. 
;
; Operation:        If no game is ongoing, the speaker does not loop the BGM. 
;                   Otherwise, a table containing note frequencies is looped 
;                   through. For each note frequency, a timer is initiated and 
;                   checked until it reaches the length of the note. The next 
;                   note frequency is then loaded and the process loops as long
;                   as currentlyPlaying is true.                    
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  currentlyPlaying - flag indicating if game is ongoing [RD]
;
; Input:             None.
; Output:            Music is played on the speakers. 
;
; Error Handling:    None.
;
; Algorithms:        Table lookup.
; Data Structures:   A table with frequencies to play for each note. 
;
; Registers Changed: R0, R16, R17, R18, R19, Z (ZH|ZL). 
;
; Author:            Emily Wu
; Last Modified:     6/14/2026--------------------------------------------------

MusicHandler:
        LDS     R16,currentlyPlaying            ; check if game is ongoing
        TST     R16
        BRNE    MH_CheckTimer                   ; if not, keep playing music
        ;BREQ   MH_StopMusic
MH_StopMusic:
        CLR     R16                             ; stop music once music is over
        CLR     R17
        RCALL   PlayNote                        ; call playNote(freq=0)
        RET

MH_CheckTimer:
        LDI     R16,MUSIC_TIMER                 ; get timer number for music
        RCALL   DelayNotDone                    ; check if current note is done
        TST     R0                              ; if R0 = 0, timer done
        BRNE    MH_Done                         ; if nonzero, keep playing 
        ;BREQ   MH_NextNote                     ; timer done then move onto next

MH_NextNote:
        LDS     R18,musicIndex                  ; get index of next note 
        LDI     ZL,LOW(2*MusicTab)              ; get beginning of table
        LDI     ZH,HIGH(2*MusicTab)

        LSL     R18                             ; multiply index by 2 to get 
                                                ;    table byte offset
        ADD     ZL,R18                          ; go to entry in table w/ note
        CLR     R19                             ; zero for carry propagation
        ADC     ZH,R19          
        LPM     R16,Z+                          ; get frequency low byte
        LPM     R17,Z                           ; get frequency high byte
        RCALL   PlayNote                        ; play this note

        LDI     R16,MUSIC_TIMER                 ; get associated timer
        LDI     XL,LOW(MUSIC_NOTE_LEN)          ; load in note length
        LDI     XH,HIGH(MUSIC_NOTE_LEN)
        RCALL   StartDelay                      ; restart timer for next note

        LDS     R18,musicIndex                  ; get current note index
        INC     R18                             ; increment to next note
        CPI     R18,MusicTab_LEN                ; check if reached last note
        BRLO    MH_Save                         ; if not, save new note index
        ;BRSH   MH_Wrap                         ; otherwise wrap around
MH_Wrap:
        CLR     R18                             ; wrap to beginning of melody

MH_Save:
        STS     musicIndex,R18                  ; store index

MH_Done:
        RET
        
; TABLES -----------------------------------------------------------------------
; GameCmdTable -----------------------------------------------------------------
;
; Description:      This is the command table for relating sensor activations to
;                   their associated functions while a game is currently ongoing
;
; Author:           Emily Wu
; Last Modified:    06/12/2026--------------------------------------------------

GameCmdTable:
	;   Sensor Label 	    Function 			            Arg	
    .DB Exit              , LOW(UpdatePlayerRound), HIGH(UpdatePlayerRound), 0
    .DB Green             , LOW(RedGreenYellow)   , HIGH(RedGreenYellow)   , 0
    .DB Red               , LOW(RedGreenYellow)   , HIGH(RedGreenYellow)   , 0
    .DB Yellow            , LOW(RedGreenYellow)   , HIGH(RedGreenYellow)   , 0
    .DB KingofHearts      , LOW(AcesKings), HIGH(AcesKings), KingofHeartsLED
    .DB KingofDiamonds    , LOW(AcesKings), HIGH(AcesKings), KingofDiamondsLED
    .DB KingofClubs       , LOW(AcesKings), HIGH(AcesKings), KingofClubsLED
    .DB KingofSpades      , LOW(AcesKings), HIGH(AcesKings), KingofSpadesLED
    .DB AceofHearts       , LOW(AcesKings), HIGH(AcesKings), AceofHeartsLED
    .DB AceofDiamonds     , LOW(AcesKings), HIGH(AcesKings), AceofDiamondsLED
    .DB AceofClubs        , LOW(AcesKings), HIGH(AcesKings), AceofClubsLED
    .DB AceofSpades       , LOW(AcesKings), HIGH(AcesKings), AceofSpadesLED
    .DB LowerYellowChange , LOW(YellowGreenChange), HIGH(YellowGreenChange), 0
    .DB UpperYellowChange , LOW(YellowGreenChange), HIGH(YellowGreenChange), 0
    .DB LowerGreenChange  , LOW(YellowGreenChange), HIGH(YellowGreenChange), 0
    .DB UpperGreenChange  , LOW(YellowGreenChange), HIGH(YellowGreenChange), 0
    .DB Wheel             , LOW(WheelHit)         , HIGH(WheelHit)         , 0
    .DB BallCavityL       , LOW(BallCavity)       , HIGH(BallCavity)       , 0
    .DB BallCavityR       , LOW(BallCavity)       , HIGH(BallCavity)       , 0
    .DB LitesYellowJoker  , LOW(LitesYellowGreen) , HIGH(LitesYellowGreen) , 0
    .DB LitesGreenJoker   , LOW(LitesYellowGreen) , HIGH(LitesYellowGreen) , 0
    .DB TriangularIslandsR, LOW(UpdateScore)      , HIGH(UpdateScore)      , 1
    .DB TriangularIslandsL, LOW(UpdateScore)      , HIGH(UpdateScore)      , 1
    .DB SideExitsR        , LOW(UpdateScore)      , HIGH(UpdateScore)      , 100
    .DB SideExitsL        , LOW(UpdateScore)      , HIGH(UpdateScore)      , 100
    .DB Tilt              , LOW(UpdatePlayerRound), HIGH(UpdatePlayerRound), 0

    ; size of the table (number of game commands)
    .equ        GAME_CMD_COUNT                  = 26

; MenuCmdTable -----------------------------------------------------------------
;
; Description:      This is the command table for relating sensor activations to
; 		    their associated functions while a game is not currently on-
;                   going.
;
; Author:           Emily Wu
; Last Modified:    06/10/2026--------------------------------------------------

MenuCmdTable:
	;   Sensor Label 	    Function 		               Arg	
	.DB StartGame         , LOW(StartButton) , HIGH(StartButton)  , 0
	.DB FlipperL          , LOW(Flipper)	 , HIGH(Flipper)      , 0

        ; size of the table (number of menu commands)
        .equ    MENU_CMD_COUNT                  = 2

; RoundInitLEDsON---------------------------------------------------------------
; 
; Description: 	    This table contains the constant names (which are associated
;                   with light numbers) that should be turned ON at the start of 
;                   each round. 
;	
; Author:           Emily Wu
; Last Modified:    06/11/2026--------------------------------------------------

RoundInitLEDsON:
        .DB KingofHeartsLED,    KingofDiamondsLED
        .DB KingofClubsLED,     KingofSpadesLED
        .DB AceofHeartsLED,     AceofDiamondsLED
        .DB AceofClubsLED,      AceofSpadesLED
        .DB RedLED,             Y10
        .DB G10

        ; size of the table (number of LEDs to turn on)
        .equ    ROUND_INIT_ON_COUNT     = 11


; RoundInitLEDsOFF -------------------------------------------------------------
;
; Description:      This table contains the constant names (which are associated
;                   with light numbers) that should be turned OFF @ the start of 
;                   each round. 
;       
; Author:           Emily Wu
; Last Modified:    06/11/2026--------------------------------------------------

RoundInitLEDsOFF:
        .DB Y20, Y30
        .DB Y40, Y50
        .DB Y60, Y70
        .DB Y80, Y90
        .DB Y100, G20
        .DB G30, G40
        .DB G50, G60
        .DB G70, G80
        .DB G90, G100
        .DB extraBallL, extraBallR
        .DB GreenLED, YellowLED
        .DB GPoints300, YPoints300
        .DB IncreasesValG, IncreasesValY
        .DB GameOver

        ; size of the table (number of LEDs to turn off)
        .equ    ROUND_INIT_OFF_COUNT    = 27

; KingAceTable -----------------------------------------------------------------
;
; Description:      This table contains the constants containing the pre-calcul-
;                   -ated rows for the kings/aces as well as masks for their 
;                   column locations.  
;       
; Author:           Emily Wu
; Last Modified:    06/11/2026--------------------------------------------------
KingAceTable:
    .DB KH_ROW, KH_MASK
    .DB KD_ROW, KD_MASK
    .DB KC_ROW, KC_MASK
    .DB KS_ROW, KS_MASK
    .DB AH_ROW, AH_MASK
    .DB AD_ROW, AD_MASK
    .DB AC_ROW, AC_MASK
    .DB AS_ROW, AS_MASK

; Joker tables -----------------------------------------------------------------
;
; Description:      These contains the constants for the light numbers for the 
;                   10-100 joker lines. 
;       
; Author:           Emily Wu
; Last Modified:    06/11/2026--------------------------------------------------

JokerTableY:
        .DB Y10,Y20,Y30,Y40,Y50,Y60,Y70,Y80,Y90,Y100

JokerTableG:
        .DB G10,G20,G30,G40,G50,G60,G70,G80,G90,G100

        ; size of the tables (number of LEDs)
        .equ    JOKER_COUNT                     = 10

; SuccessTab -------------------------------------------------------------------
;
; Description:      This table contains the tune to play when a new high score
;                   is set. 
;       
; Author:           Emily Wu
; Last Modified:    06/12/2026--------------------------------------------------

SuccessTab:

        .DW     523, 523, 392, 392 
        .DW     587, 587, 698, 659
        .DW     0,   0,    0,  392
        .DW     392, 784, 698, 659
        .DW     0,   0,    0,  494
        .DW     392, 587, 698, 1046
        .DW     1046, 1046, 0,   0

        ;size of the table (number of notes)
        .EQU    SuccessTab_LEN = 28

; Music Tab --------------------------------------------------------------------
;
; Description:      This table contains the tune to play throughout a game. 
;       
; Author:           Emily Wu
; Last Modified:    06/12/2026--------------------------------------------------

MusicTab:

        .DW     523, 523, 392, 392 
        .DW     587, 587, 698, 659
        .DW     0,   0,    0,  392
        .DW     392, 784, 698, 659
        .DW     0,   0,    0,  494
        .DW     392, 587, 698, 1046
        .DW     1046, 1046, 0,   0

        ;size of the table (number of notes)
        .EQU    MusicTab_LEN = 28

; data segment -----------------------------------------------------------------
.dseg
currentlyPlaying:	.BYTE  1 	; flag indicating if a game is ongoing.
currentPlayer:		.BYTE  1 	; player number between 1 and 4
currentRound: 		.BYTE  1 	; each round, each player gets one turn 
					;   after each player has played the max
					;   number of rounds, the entire game 
					;   ends. 
numPlayers: 		.BYTE  1        ; Players can indicate if they want 1 to
					;    4 players by pressing the flipper
					;    button (left side) 1 to 4 times.
extraBall:		.BYTE  1 	; flag indicating if current player
					;    will receive an additional ball.
sensorCode: 		.BYTE  1 	; the code for the most recently deboun-
					;    -ced sensor activation. 
yellowCounter: 		.BYTE  1        ; counter for the 10-100 LED line yellow
greenCounter: 		.BYTE  1 	; counter for the 10-100 LED line green

currentScores: 		.BYTE  8 	; buffer with players' current scores.
					;     each score is stored in 16-bit 
					;     binary.

highScore: 		.BYTE  1      ; stores all-time high score
newHighScoreSet:        .BYTE  1      ; flag indicating if new high score set

actuatorActive:         .BYTE  8      ; flag for if an actuator is on
cavityActive:           .BYTE  1      ; flag for if cavity sequence is active
cavitySide:             .BYTE  1      ; active joker side: 0=green/L, 1=yellow/R
cavityCount:            .BYTE  1      ; LEDs remaining

musicIndex:             .BYTE  1      ; current note number