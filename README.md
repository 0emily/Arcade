# Arcade
The system is a pinball machine consisting of sensors, LEDs, a speaker responsible for sound effects, and a serial EEROM
for storing high scores. The sensors are located throughout the playing field. When activated, the sensors cause the score
to increase by an appropriate amount. Four 4-digit 7-segment displays indicate the current score for the four-player game.
In a single game, players begin by selecting the number of total players between 1 and 4 (inclusive). The game cycles
through each player until all players have played five rounds, with each round consisting of a default of one ball. There is
the opportunity to introduce more balls into play if certain sensors are activated. After all players have played five rounds,
the game ends, high score(s) are logged (if applicable), and the left flipper button may be pressed to initiate another game
by setting the new number of players.

