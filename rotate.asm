.eqv	headeraddr 0
.eqv    filesize   4
.eqv	imgaddr    8
.eqv	imgwidth   12
.eqv    imgheight  16
.eqv    rowsize    20

		.data
	
imgdescriptor:	.word 0
		.word 0
		.word 0
		.word 0
		.word 0
		.word 0

img:		.space 	318				# size of file
fname:		.asciiz "smile24x64.bmp"		# name of source file
outfname: 	.asciiz "out.bmp"			# name of destination file
error:		.asciiz	"error in opening file"		# error message
success: 	.asciiz "image rotated successfully"	# success message

		.text
main:
	la $a0, fname
	li $a1, 0
	li $a2, 0
	jal open_bmp_file

	la $a1, img
	li $a2, 318				# size of file
	jal read_bmp_file

	la $a0, imgdescriptor
	jal save_data

	la $a0, fname
	li $a1, 0
	li $a2, 0
	jal open_and_allocate
	
	
### load accessory addresses to registers ###
	la $t5, ($t8)		# accessory destination address
	la $t6, 62($t1)		# accessory source address

	li $s7, 0		# counter of bytes read in column

	move  $a0, $t3		
	addiu $a0, $a0, 31
	srl $a0, $a0, 5
	sll $a0, $a0, 2		
	
	move $a1, $t3		
	subiu $a1, $a1, 1	
	mul $a1, $t0, $a1	# a1 = (height - 1) * rowsize
	
	jal main_loop
	
	
	move  $s1, $t3		
	addiu $s1, $s1, 31
	srl $s1, $s1, 5
	sll $s1, $s1, 2		

	mul $s3, $s1, $t2	# s3 - memory size for rotated file in bytes
	la $t5, ($t8)		
	la $t6, 62($t1)		
	
	la $a0, outfname
	li $a1, 9
	li $a2, 0
	jal save_header
	
	la $a1, ($t8)		
	la $a2, ($s3)		 
	
	jal save_destination
	
	jal close_bmp_file
	
	
ferror:
	li $v0, 4
	la $a0, error
	syscall

main_exit:	
	li $v0, 10
	syscall
	
	
open_bmp_file:
	li $v0, 13
	syscall
	bltz $v0, ferror
	move $a0, $v0
	
	jr $ra
read_bmp_file:
	li $v0, 14
	syscall
	move $t0, $v0
	li $v0, 16
	syscall
	
	jr $ra

save_data:
	sw $t0, filesize($a0)
	sw $a1, headeraddr($a0)
	lhu $t0, 10($a1) 
	addu $t1, $a1, $t0
	sw $t1, imgaddr($a0) 
	lhu $t0, 18($a1)    
	sw $t0, imgwidth($a0) 
	lhu $t0, 22($a1)     
	sw $t0, imgheight($a0) 

	lw $t0, imgwidth($a0)
	addiu $t0, $t0, 31
	srl $t0, $t0, 5
	sll $t0, $t0, 2
	sw $t0, rowsize($a0)
	
# load data to registers
	lw $t7, filesize($a0)
	lw $t2, imgwidth($a0)
	lw $t3, imgheight($a0)
	lw $t0, rowsize($a0)
	jr $ra

open_and_allocate:
# reopen file
	li $v0, 13
	syscall
	move $t4, $v0			# file descriptor
	
### CALCULATE PADDING ###
	li $s6, 4		# load accessory 4 to s6
	srl $t2, $t2, 3		# divide width by 8
	and $t9, $t2, 7		# remainder of division width in bytes by 8
	sll $t2, $t2, 3
	sub $t9, $s6, $t9	# t9 = 4 - remainder
# if padding = 4 then subtract 4
	bne $t9, 4, allocate
	subu $t9, $t9, 4	


allocate:
# allocate memory for whole file
	la $a0, ($t7)
	li $v0, 9
	syscall
	move $t1, $v0 		# address of block of memory allocated for source file
	
# calculate needed memory for destination file
	move  $s1, $t3		# height of file to s1
	addiu $s1, $s1, 31
	srl $s1, $s1, 5
	sll $s1, $s1, 2		# s1 - width of row in bytes (height of source file in bytes)
	
	mul $s3, $s1, $t2	# s3 - memory size of destination file in bytes
	
# allocate memory for destination file
	move $a0, $s3 		# how many bytes need to be allocated 
	li $v0, 9
	syscall
	move $t8, $v0		# address of block of memory allocated for destination file

# laod whole file into currently allocated memory
	move $a0, $t4 
	la $a1, ($t1) 		
	la $a2, ($t7) 		
	li $v0, 14
	syscall

# close file
	li $v0, 16
	syscall
	
	jr $ra
	

main_loop:
	li $s6 0		# number of bytes that have already been read in row 

	add $s6, $s6, $t9	# add padding
	add $t6, $t6, $a1	# top left corner of not rotated file
	mul $s0, $s7, $t2	# s0 = number of read bytes in column * width in pixels
# subtract from start address
	sub $t6, $t6, $s0
	add $t5, $t5, $s7
# if column has been read then subtract padding * 8
	sll $s0, $t9, 3
	mul $s0, $s0, $s7	
	sub $t6, $t6, $s0
	
	li $s0, 0		# width counter
	
width_loop:
	li $s1, 0		# register for storing pixels
	li $s2, 0x80		# bitmask
	li $s3, 8
	and $s4, $s0, 7
	srlv $s2, $s2, $s4	# shift bitmask right for number of remainder 
	
	li $s4, 0		# heigth counter
	
height_loop:
	lb $s5, ($t6)		# first top byte
	and $s5, $s5, $s2	# AND with bitmask
	sllv $s5, $s5, $s0
	srlv $s5, $s5, $s4
	addu $s1, $s1, $s5	# store pixel in register
	addiu $s4, $s4, 1	# increment height counter
	subu $t6, $t6, $t0	# subtract rowsize from address from which I read 
	bltu $s4, 8, height_loop
	
# store byte that was read to destination memory 
	sb $s1, ($t5)		# store byte
	addiu $s0, $s0, 1	# increment width counter
# check if all column was read - repeat loop if remainder of division of width counter by 8 is not equal 0
	and $s3, $s0, 7
	add $t6, $t6, $t2	# add rowsize to address from which I read
	sll $s1, $t9, 3		# padding
	add $t6, $t6, $s1
	add $t5, $t5, $a0	# add row to address to which I store

	bnez $s3, width_loop
	
	li $s0, 0		# zero to width counter
	addiu $s6, $s6, 1	# increment counter of read bytes in row
	addiu $t6, $t6, 1	# move address from which I read
# if number of read bytes < rowsize then repeat width_loop
	blt $s6, $t0, width_loop
# if end of width is reached check height
	addiu $s7, $s7, 1	# add byte to read bytes in column
# if number of read bytes in column < height in bytes then repeat
	la $t5, ($t8)		# roboczy adres na wyjœcie
	la $t6, 62($t1)		# roboczy adres pocz¹tkowy

	blt $s7, $a0, main_loop

	jr $ra

save_header:
	li $v0, 13
	syscall
	move $s1, $v0 		# file descriptor
	bltz $s1, ferror

	la $a0, ($s1)
	la $a1, ($t1)		# address of block in memory
	la $a2, 18		# 18 first bytes
	li $v0, 15
	syscall
	
# substitute height for width
	la $a0, ($s1)
	la $a1, 22($t1)
	la $a2, 4
	li $v0, 15
	syscall
# substitute width for height
	la $a0, ($s1)
	la $a1, 18($t1)
	la $a2, 4
	li $v0, 15
	syscall
	
# the rest without change
	la $a0, ($s1)
	la $a1, 26($t1)
	la $a2, 36
	li $v0, 15
	syscall
	
	jr $ra
	
save_destination:
	li $v0, 15
	syscall
	
	jr $ra
	
# close file
close_bmp_file:
	move $a0, $s1
	li $v0, 16
	syscall
	
	li $v0, 4
	la $a0, success
	syscall
	
	j main_exit
