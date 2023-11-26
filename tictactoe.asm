.macro print (%label)
li $v0, 4
la $a0, %label
syscall
.end_macro

.macro printAddress (%address)
li $v0, 4
move $a0, %address
syscall
.end_macro

.macro printFloat (%r)
li $v0, 2
mov.s $f12, %r
syscall
.end_macro

.macro printInt (%r)
li $v0, 1
move $a0, %r
syscall
.end_macro

.macro printCharAdr (%r)
li $v0, 11
lb $a0, (%r)
syscall
.end_macro

.macro printCharLbl (%r)
li $v0, 11
lb $a0, %r
syscall
.end_macro

.macro beginFunc
sw $fp, -4($sp)
sw $ra, -8($sp)
addi $sp, $sp, -8
move $fp, $sp
.end_macro

.macro return
la $sp, 8($fp)
lw $ra, ($fp)
lw $fp, 4($fp)
jr $ra
.end_macro

.macro readString (%label, %count)
li $v0, 8
la $a0, %label
li $a1, %count
syscall
.end_macro

.macro readChar
li $v0, 12
syscall
.end_macro

.macro readDigit
li $v0, 12
syscall
addi $v0, $v0, -48
.end_macro

.macro exit
li $v0, 10
syscall
.end_macro

.data
	askNoRoundsMsg: .asciiz "\nWybierz liczbe rund (1-5): \n"
	badNoRoundsMsg: .asciiz "\nNieprawidlowy wybor\n"

	askCharacterMsg: .asciiz "\nWybierz swoj znak (kolko - 0, krzyzyk 1): "
	badCharacterMsg: .asciiz "\nNieprawidlowy wybor\n"
	
	computerWinsMsg: .asciiz "\nLiczba wygranych komputera: "
	playerWinsMsg: .asciiz "\nLiczba wygranych gracza: "
	
	askFieldMsg: .asciiz "\nPodaj pole (1-9): "
	badFieldMsg: .asciiz "\nNieprawidlowe pole\n"
	
	aiWon: .asciiz "\Komputer wygral\n"
	playerWon: .asciiz "\nGracz wygral\n"
	draw: .asciiz "\nRemis\n"
	
	endl: .byte 10

	player: .byte 88
	ai: .byte 79
	blank: .byte 46 

	lines: .byte -1 -2 -3, -4 -5 -6, -7 -8 -9, -1 -4 -7, -2 -5 -8, -3 -6 -9, -1 -5 -9, -7 -5 -3
.text
	#s0 - number of rounds
	#s1 - player wins
	#s2 - computer wins
	#s3 - address of the board
	main:
		move $fp, $sp
		move $s3, $fp
		move $a0, $fp
		jal setupBoard
		addi $sp, $sp, -12
		
		
		jal getNoRounds
		playRounds:
			beqz $s0, endGame
			jal getPlayerCharacter
			jal executeRound
			addi $s0, $s0, -1
			j playRounds
			
		endGame:
			jal printResult
			exit

		
		exit
		
	getNoRounds:
		print (askNoRoundsMsg)
		readDigit
		blez $v0, badNoRounds
		bgt $v0, 5, badNoRounds
		
		move $s0, $v0
		jr $ra
		
		badNoRounds:
			print (badNoRoundsMsg)
			j getNoRounds
	
	getPlayerCharacter:
		print (askCharacterMsg)
		readDigit
		beqz $v0, playerCircle
		beq $v0, 1, playerCross
		print (badCharacterMsg)
		j getPlayerCharacter
		
		playerCircle:
			li $v0, 79
			sb $v0, player
			li $v0, 88
			sb $v0, ai
			jr $ra
			
		playerCross:
			li $v0, 79
			sb $v0, ai
			li $v0, 88
			sb $v0, player
			jr $ra
	
	printResult:
		print (playerWinsMsg)
		printInt ($s1)
		print (computerWinsMsg)
		printInt ($s2)
		jr $ra
		
	#Actual Round section -----------------
	executeRound:
		beginFunc
		
		move $a0, $s3
		jal setupBoard
		
		makePlayerMove:
			move $a0, $s3
			jal askPlayerMove
			add $t0, $s3, $v0
			lb $t1, player
			sb $t1, ($t0)
			
			move $a0, $s3
			jal drawBoard
			
			move $a0, $s3
			jal getGameState
			beqz $v0, makeComputerMove
			j endRound
			
		
		makeComputerMove:
			move $a0, $s3
			jal getBestAiMove
			add $t0, $s3, $v0
			lb $t1, ai
			sb $t1, ($t0)
			
			move $a0, $s3
			jal drawBoard
			
			move $a0, $s3
			jal getGameState
			beqz $v0, makePlayerMove
			j endRound
		
		
		endRound:
			seq $t0, $v0, 1
			seq $t1, $v0, 2
			add $s1, $s1, $t0
			add $s2, $s2, $t1
			
			bne $t0, 1, skipPlayerWinMsg
			print (playerWon)
			skipPlayerWinMsg:
			
			bne $t1, 1, skipAiWinMsg
			print (aiWon)
			skipAiWinMsg:
			
			or $t0, $t0, $t1
			bne $t0, 0, skipDrawMsg
			print(draw)
			skipDrawMsg:
			
			return
		
	
		
	askPlayerMove:
		#a0 - address of first cell
		#v0 - no chosen cell [-1, -9]
		move $t0, $a0
		
		askMove:
			printCharLbl (endl)
			print(askFieldMsg)
			readDigit
			blez $v0, badMoveAsked
			bgt $v0, 9, badMoveAsked
			
			neg $v0, $v0
			add $t1, $t0, $v0
			lb $t2, blank
			lb $t1, ($t1)
			bne $t2, $t1, badMoveAsked
			
			move $t0, $v0
			printCharLbl(endl)
			move $v0, $t0
			jr $ra
			
		badMoveAsked:
			print(badFieldMsg)
			j askMove
		
		
		
	
	setupBoard:
		#a0 - address of first cell
		lb $t0, blank #inital cell state
		lb $t1, player
		lb $t2, ai
		
		sb $t0, -1($a0)
		sb $t0, -2($a0)
		sb $t0, -3($a0)
		sb $t0, -4($a0)
		sb $t0, -5($a0)
		sb $t0, -6($a0)
		sb $t0, -7($a0)
		sb $t0, -8($a0)
		sb $t0, -9($a0)
		jr $ra
		
	copyBoard:
		#a0 - address of first board
		#a1 - address of new board
		#saves registers
		addi $sp, $sp, -4
		sw $t0, ($sp)
		
		lb $t0, -1($a0)
		sb $t0, -1($a1)
		
		lb $t0, -2($a0)
		sb $t0, -2($a1)
		
		lb $t0, -3($a0)
		sb $t0, -3($a1)
		
		lb $t0, -4($a0)
		sb $t0, -4($a1)
		
		lb $t0, -5($a0)
		sb $t0, -5($a1)
		
		lb $t0, -6($a0)
		sb $t0, -6($a1)
		
		lb $t0, -7($a0)
		sb $t0, -7($a1)
		
		lb $t0, -8($a0)
		sb $t0, -8($a1)
		
		lb $t0, -9($a0)
		sb $t0, -9($a1)
		
		lw $t0, ($sp)
		addi $sp, $sp, 4
		jr $ra
		
	
	drawBoard:
		#a0 - address of first cell
		
		sw $t0, -4($sp)
		sw $a0, -8($sp)
		move $t0, $a0
		
		#row 1
		addi $t0, $t0, -1
		printCharAdr ($t0)
		addi $t0, $t0, -1
		printCharAdr ($t0)
		addi $t0, $t0, -1
		printCharAdr ($t0)
		printCharLbl (endl)
		
		#row 2
		addi $t0, $t0, -1
		printCharAdr ($t0)
		addi $t0, $t0, -1
		printCharAdr ($t0)
		addi $t0, $t0, -1
		printCharAdr ($t0)
		printCharLbl (endl)
		
		#row 3
		addi $t0, $t0, -1
		printCharAdr ($t0)
		addi $t0, $t0, -1
		printCharAdr ($t0)
		addi $t0, $t0, -1
		printCharAdr ($t0)
		printCharLbl (endl)
		printCharLbl (endl)
		
		lw $t0, -4($sp)
		lw $a0, -8($sp)
		jr $ra
	
	getGameState:
		#uses t0, t1, t2
		#a0 - address of first cell
		#v0 - state (0 - game continues, 1-player wins, 2-ai wins, 3-draw)
		beginFunc
		# first horizontal row
		lb $t0, -1($a0)
		lb $t1, -2($a0)
		lb $t2, -3($a0)
		jal checkForWin
		bnez $v0, returnStateWin
		
		# second horizontal row
		lb $t0, -4($a0)
		lb $t1, -5($a0)
		lb $t2, -6($a0)
		jal checkForWin
		bnez $v0, returnStateWin
		
		# third horizontal row
		lb $t0, -7($a0)
		lb $t1, -8($a0)
		lb $t2, -9($a0)
		jal checkForWin
		bnez $v0, returnStateWin
		
		# first vertical row
		lb $t0, -1($a0)
		lb $t1, -4($a0)
		lb $t2, -7($a0)
		jal checkForWin
		bnez $v0, returnStateWin
		
		# second vertical row
		lb $t0, -2($a0)
		lb $t1, -5($a0)
		lb $t2, -8($a0)
		jal checkForWin
		bnez $v0, returnStateWin
		
		# third vertical row
		lb $t0, -3($a0)
		lb $t1, -6($a0)
		lb $t2, -9($a0)
		jal checkForWin
		bnez $v0, returnStateWin
		
		# rising diagonal
		lb $t0, -7($a0)
		lb $t1, -5($a0)
		lb $t2, -3($a0)
		jal checkForWin
		bnez $v0, returnStateWin
		
		# declining diagonal
		lb $t0, -1($a0)
		lb $t1, -5($a0)
		lb $t2, -9($a0)
		jal checkForWin
		bnez $v0, returnStateWin
		
		j checkForDraw
		
		checkForWin:
			#checks registers
			seq $t0, $t0, $t1
			seq $t1, $t1, $t2
			and $t0, $t0, $t1
			beqz $t0, noWin
			lb $t1, player
			beq $t1, $t2, playerWin
			lb $t1, ai
			beq $t1, $t2, aiWin
			
			noWin:
				li $v0, 0
				jr $ra
			
			playerWin:
				li $v0, 1
				jr $ra
			aiWin:
				li $v0, 2
				jr $ra
				
		returnStateWin:
			return
			
		checkForDraw:
		li $t0, 0
		checkNextCellDraw:
			addi $t0, $t0, -1
			beq $t0, -10, returnGameDraws
			li $t1, 0
			add $t1, $a0, $t0
			lb $t2, ($t1)
			lb $t1, blank
			beq $t2, $t1, returnGameContinues
			j checkNextCellDraw
			
		returnGameDraws:
			li $v0, 3
			return
			
		returnGameContinues:
			li $v0, 0
			return


	testRandomGames:
		move $fp, $sp
		addi $sp, $sp, -12
		
		li $s2, 30 #number of rounds
		
		randomRound:
			move $a0, $fp
			jal setupBoard
			
			li $s0, 0	#game state
			li $s1, 88	#88 - player move, 79-computer move
			
			doAction:
				move $a0, $fp
				jal getRandomMove
				
				move $t0, $fp
				add $t0, $t0, $v0   #pointer to cell
				sb $s1, ($t0)		#make move
				
				beq $s1, 88, makeAiTurn
				j makePlayerTurn
				
				makePlayerTurn:
				li $s1, 88
				j skipMakeTurn
				makeAiTurn:
				li $s1, 79
				j skipMakeTurn
				
				skipMakeTurn:
				move $a0, $fp
				jal getGameState
				move $s0, $v0
				bnez $s0, endTestRound
				j doAction
				
			endTestRound:
				move $a0, $fp
				jal drawBoard
				printInt($s0)
				printCharLbl (endl)
				printCharLbl (endl)
				
				addi $s2, $s2, -1
				bnez $s2, randomRound
				
				exit
		exit
		
	getBestAiMove:
		#a0 - address of the board
		#v0 - selected move [-1, -9]
		beginFunc
		move $t0, $a0	# pointer to start of the board
		li $t1, 0		# current line (always divisible by 3)
		lb $t7, ai
		
		checkWinMoveLoop:
			beq $t1, 24, endCheckWinMoveLoop
			
			lb $t2, lines($t1) 	# t2 - cell number
			add $t2, $t2, $t0		# t2 - cell address
			lb $t2, ($t2)			# t2 - char under cell address
			
			lb $t3, lines + 1($t1) 	# t3 - cell number
			add $t3, $t3, $t0		# t3 - cell address
			lb $t3, ($t3)			# t3 - char under cell address
			
			lb $t4, lines + 2($t1) 	# t4 - cell number
			add $t4, $t4, $t0		# t4 - cell address
			lb $t4, ($t4)			# t4 - char under cell address
			
			seq $t5, $t2, $t7		# t5 - 1 cell is ai
			seq $t6, $t3, $t7		# t6 - 2 cell is ai
			and $t5, $t5, $t6		# t5 - 1 and 2 cell is ai
			seq $t6, $t4, 46		# t6 - 3 cell is blank
			and $t5, $t5, $t6		# t5 - 1,2=ai, 3=blank
			lb $v0, lines + 2($t1)	# load 3rd cell to return address
			bnez $t5, returnMove	# return if t5 is true
			
			seq $t5, $t2, $t7		# t5 - 1 cell is ai
			seq $t6, $t4, $t7		# t6 - 3 cell is ai
			and $t5, $t5, $t6		# t5 - 1 and 3 cell is ai
			seq $t6, $t3, 46		# t6 - 2 cell is blank
			and $t5, $t5, $t6		# t5 - 1,3=ai, 2=blank
			lb $v0, lines + 1($t1)	# load 2rd cell to return address
			bnez $t5, returnMove	# return if t5 is true
			
			seq $t5, $t4, $t7		# t5 - 3 cell is ai
			seq $t6, $t3, $t7		# t6 - 2 cell is ai
			and $t5, $t5, $t6		# t5 - 3 and 2 cell is ai
			seq $t6, $t2, 46		# t6 - 1 cell is blank
			and $t5, $t5, $t6		# t5 - 3,2=ai, 1=blank
			lb $v0, lines($t1)	# load 1rd cell to return address
			bnez $t5, returnMove	# return if t5 is true
			
			addi $t1, $t1, 3
			j checkWinMoveLoop

		
		endCheckWinMoveLoop:
		li $t1, 0		# current line (always divisible by 3)
		lb $t7, player
		checkBlockMoveLoop:
			beq $t1, 24, goRandomMove
			
			lb $t2, lines($t1) 	# t2 - cell number
			add $t2, $t2, $t0		# t2 - cell address
			lb $t2, ($t2)			# t2 - char under cell address
			
			lb $t3, lines + 1($t1) 	# t3 - cell number
			add $t3, $t3, $t0		# t3 - cell address
			lb $t3, ($t3)			# t3 - char under cell address
			
			lb $t4, lines + 2($t1) 	# t4 - cell number
			add $t4, $t4, $t0		# t4 - cell address
			lb $t4, ($t4)			# t4 - char under cell address
			
			seq $t5, $t2, $t7		# t5 - 1 cell is player
			seq $t6, $t3, $t7		# t6 - 2 cell is player
			and $t5, $t5, $t6		# t5 - 1 and 2 cell is player
			seq $t6, $t4, 46		# t6 - 3 cell is blank
			and $t5, $t5, $t6		# t5 - 1,2=ai, 3=blank
			lb $v0, lines + 2($t1)	# load 3rd cell to return address
			bnez $t5, returnMove	# return if t5 is true
			
			seq $t5, $t2, $t7		# t5 - 1 cell is player
			seq $t6, $t4, $t7		# t6 - 3 cell is player
			and $t5, $t5, $t6		# t5 - 1 and 3 cell is player
			seq $t6, $t3, 46		# t6 - 2 cell is blank
			and $t5, $t5, $t6		# t5 - 1,3=ai, 2=blank
			lb $v0, lines + 1($t1)	# load 2rd cell to return address
			bnez $t5, returnMove	# return if t5 is true
			
			seq $t5, $t4, $t7		# t5 - 3 cell is player
			seq $t6, $t3, $t7		# t6 - 2 cell is player
			and $t5, $t5, $t6		# t5 - 3 and 2 cell is player
			seq $t6, $t2, 46		# t6 - 1 cell is blank
			and $t5, $t5, $t6		# t5 - 3,2=ai, 1=blank
			lb $v0, lines($t1)	# load 1rd cell to return address
			bnez $t5, returnMove	# return if t5 is true
			
			addi $t1, $t1, 3
			j checkBlockMoveLoop
			
		goRandomMove:
		jal getRandomMove
		return
		
		returnMove:
			return
		
	
	getRandomMove:
		#v0 - number of cell to make the move
		#a0 - adress of first cell
		move $v1, $a0
		getRandomMoveLoop:
			li $a0, 0
			li $a1, 9
			li $v0, 42
			syscall
			
			neg $a0, $a0		#[0, 8] range to [-8, 0]
			addi $a0, $a0, -1   #[-8, 0] range to [-9, -1]
			
			add $a1, $a0, $v1	#make $a1 memory pointer
			lb $a2, blank		#make $a2 blank char
			lb $v0, ($a1)		#load cell to v0
			bne $a2, $v0, getRandomMoveLoop
			
		returnRandomMove:
			move $v0, $a0
			jr $ra