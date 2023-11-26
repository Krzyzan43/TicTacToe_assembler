# TicTacToe assembler

This is a single file tic-tac-toe game written in MIPS assembler. You can play against an AI.

# Features
  - AI that you can win with (it plays randomly unless the game is one move from ending)
  - Selecting number of rounds -> 1-5 rounds, at the end of the game you can see the score
  - Completely error prone, if you type something wrong thing you will be asked to type it again
  - You can select if you want to play with X or O

# Running
  Unfortunately, code is too complex for online assembly runners. The easiest way to run it is from 'MARS MIPS Simulator', which can be downloaded from https://courses.missouristate.edu/kenvollmar/mars/. In order to play the game, you just need to open the tictactoe.asm file in mars and run it.

# Example
  This is an example of running the game
  ```
  Wybierz liczbe rund (1-5): 2
  Wybierz swoj znak (kolko - 0, krzyzyk 1): 1
  
  Podaj pole (1-9): 5  
  ...
  .X.
  ...
  
  ...
  .XO
  ...
  
  Podaj pole (1-9): 1  
  X..
  .XO
  ...
  
  X..
  .XO
  ..O
  
  Podaj pole (1-9): 3
  X.X
  .XO
  ..O
  
  XOX
  .XO
  ..O
  
  Podaj pole (1-9): 7
  XOX
  .XO
  X.O

  Gracz wygral

  
  Wybierz swoj znak (kolko - 0, krzyzyk 1): 0
  
  Podaj pole (1-9): 1
  O..
  ...
  ...
  
  O..
  ..X
  ...
  
  Podaj pole (1-9): 4
  O..
  O.X
  ...
  
  O..
  O.X
  X..
  
  Podaj pole (1-9): 5
  O..
  OOX
  X..
  
  O..
  OOX
  X.X
  
  Podaj pole (1-9): 8
  O..
  OOX
  XOX
  
  O.X
  OOX
  XOX


  Komputer wygral

  
  Liczba wygranych gracza: 1
  Liczba wygranych komputera: 1
```
