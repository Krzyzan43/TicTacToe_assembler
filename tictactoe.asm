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

.macro beginFunc
addi $sp, $sp, -4
sw $ra, ($sp)
.end_macro

.macro return
lw $ra, ($sp)
addi $sp, $sp, 4
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

.data
	input: .space 51
	endl: .asciiz "\n"
	askOperation: .asciiz "\nWybierz dzialanie: \n1. dodawanie \n2. odejmowanie \n3. mnozenie \n4. dzielenie \n"
	invalidOperationMsg: .asciiz "\nNieprawidlowy wybor\n"
	invalidFloatMsg: .asciiz "\nPodano nieprawidlowa liczbe\n"
	div0ErrorMsg: .asciiz "\nBlad dzielenia przez 0\n"
	askAMsg: .asciiz "\nPodaj a: "
	askBMsg: .asciiz "\nPodaj b: "
	resultMsg: .asciiz "\nWynik: "
	continueMsg: .asciiz "\nCzy kontynuwac? (nie - 0, tak - 1): "
	wrongChoice: .asciiz "\nNieprawidlowy wybor"
	
	tenth: .float 0.1
	ten: .float 10
	one: .float 1
	zero: .float 0
.text
	main:
		jal getOperation
		move $a0, $v0
		jal executeOperation
		jal askToContinue
		
		bnez $v0, main
		
		endExecution:
		li $v0, 10
		syscall
		
	getOperation:
		#v0 - operation to be made
		#loops until user types correct operation
		print (askOperation)
		readDigit
		blez $v0, invalidOperation
		bgt $v0, 4, invalidOperation
		move $t0, $v0
		print (endl)
		move $v0, $t0
		jr $ra
		
		invalidOperation:
			print (invalidOperationMsg)
			j getOperation
		
	executeOperation:
		beginFunc
		#a0 - operation to execute
		move $s0, $a0
		
		la $a0, askAMsg
		jal readFloat
		mov.s $f12, $f0
		
		la $a0, askBMsg
		jal readFloat
		mov.s $f13, $f0
		
		beq $s0, 1, executeAdd
		beq $s0, 2, executeSub
		beq $s0, 3, executeMul
		beq $s0, 4, executeDiv
		
		printOpResult:
		print (resultMsg)
		printFloat ($f12)
		
		endExecuteOperation:
			return
		
		executeAdd:
		add.s $f12, $f12, $f13
		j printOpResult
	
		executeSub:
		sub.s $f12, $f12, $f13
		j printOpResult
	
		executeMul:
		mul.s $f12, $f12, $f13
		j printOpResult
	
		executeDiv:
		l.s $f0, zero
		c.eq.s $f0, $f13
		bc1t div0Error
		
		div.s $f12, $f12, $f13
		j printOpResult
		
		div0Error:
		print (div0ErrorMsg)
		j endExecuteOperation
		
	askToContinue:
		print (continueMsg)
		readDigit
		bltz $v0, invalidDigit
		bgt $v0, 2, invalidDigit
		jr $ra
		
		invalidDigit:
			print (wrongChoice)
			j askToContinue
		
	readFloat:
		#a0 - message to display
		beginFunc
		move $t8, $a0
		
		tryRead:
			printAddress ($t8)
			readString (input, 51)
			jal parseFloat
			bnez $v0, invalidFloat
			return
			
		invalidFloat:
			print (invalidFloatMsg)
			j tryRead
		
	parseFloat:
		addi $sp, $sp, -4
		sw $ra, ($sp)
	
		la $t0, input   #t0 - pointer to character in string
		li $t1, 0 	 	#t1 - character index
		li $t2, 0		#t2 - current character
		
		li $t3, 0		#t3 - number of characters before dot
		li $t4, 0		#t4 - number of characters after the dot
		li $v0, 0		#v0 - error code (0-good)
		
		parseCharacter:
			lb $t2, ($t0)
			beq $t2, 10, wrongParse
			beqz $t2, wrongParse
			bne $t2, 45, parseBeforeComa
			
			addi $t0, $t0, 1
		
			parseBeforeComa:
			lb $t2, ($t0)
			beqz $t2, endParse		# character is null (string terminated)
			beq $t2, 10, endParse	# character is endl
			
			beq $t2, 44, handleComa
			beq $t2, 46, handleComa
			
			blt $t2, 48, wrongParse
			bgt $t2, 57, wrongParse
			
			addi $t0, $t0, 1
			addi $t3, $t3, 1
			j parseBeforeComa
			
			
			handleComa:
			addi $t0, $t0, 1
			j parseAfterComa
				
				
			parseAfterComa:
			lb $t2, ($t0)
			beqz $t2, endParse		# character is null (string terminated)
			beq $t2, 10, endParse	# character is endl
				
			blt $t2, 48, wrongParse
			bgt $t2, 57, wrongParse
			
			addi $t0, $t0, 1
			addi $t4, $t4, 1
			j parseAfterComa
			
			wrongParse:
			li $v0, 1
			j exitFunc
			
			endParse:
			li $v0, 0
			move $a0, $t3
			move $a1, $t4
			jal calculateFloat
			
			j exitFunc
			
			exitFunc:
			lw $ra, ($sp)
			addi $sp, $sp, 4
			jr $ra
		
	calculateFloat:
		addi $sp, $sp, -4
		sw $ra, ($sp)
		
		move $t0, $a0 # no digits before dot
		move $t1, $a1 # no digits after dot
		la $t2, input # pointer to string
		l.s $f11, zero
		
		lb $a0, ($t2)
		seq $t3, $a0, 45
		add $t2, $t2, $t3
		
		addi $t0, $t0, -1 # loop counter (exponent) (reverse loop)
		calculateBeforeComa:
		bltz $t0, endCalculateBeforeComa
			
		lb $a0, ($t2)
		addi $a0, $a0, -48
		move $a1, $t0
		jal powerTen
		add.s $f11, $f11, $f2
			
		addi $t0, $t0, -1
		addi $t2, $t2, 1
		j calculateBeforeComa
		
		
		endCalculateBeforeComa:
		addi $t2, $t2, 1	# character pointer
		li $t0, -1			# current exponent
		
		
		calculateAfterComa:
		beqz $t1, endCalculateAfterComa
			
		lb $a0, ($t2)
		addi $a0, $a0, -48
		move $a1, $t0
		jal powerTen
		add.s $f11, $f11, $f2
			
		addi $t1, $t1, -1
		addi $t0, $t0, -1
		addi $t2, $t2, 1
		j calculateAfterComa
		
		
		endCalculateAfterComa:
		mov.s $f0, $f11
		beqz $t3, skipNegate
		neg.s $f0, $f0
		skipNegate:
		
		lw $ra, ($sp)
		addi $sp, $sp, 4
		jr $ra
		
		
	powerTen: # a * 10^n 
		#a0 - a
		#a1 - n
		#f2 - result
		# uses no temp integer registers
		
		sw $a0, -32($sp)	# move a to stack
		l.s $f8, -32($sp) 	# read from stack to f8
		cvt.s.w $f8, $f8 	# convert from int to float
		
		l.s $f9, one
		l.s $f10, ten		#save base in f10
		
		bgez $a1, skipReverseTen # convert from 10^-n to 0.1^n	
		l.s $f10, tenth
		neg $a1, $a1
		skipReverseTen:
		
		# current memory layout:
		# $f8 - a
		# $f9 - 1 (current exponent)
		# $f10 - 10 or 0.1
		increaseExponent:
			beqz $a1, endPower
			mul.s $f9, $f9, $f10
			addi $a1, $a1, -1
			j increaseExponent
		
		endPower:
			mul.s $f2, $f8, $f9
			jr $ra
			
	printEndl:
		
		li $v0, 4
		la $a0, endl
		syscall
		
		jr $ra
