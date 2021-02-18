# BMP Image rotation in MIPS assembly

## Table of Contents

- [About](#about)
- [Usage](#usage)

## About <a name = "about"></a>

Project for ARKO (Computer Architecture) course at Warsaw University of Technology. Project is implemented in MIPS Assembly. Its purpose is to simply rotate BMP image by 90 degrees clockwise.

## Usage <a name = "usage"></a>

- Clone repo.
- Open `rotate.asm` in `Mars4_5.jar`
- Set name of file you want to rotate in line 18:

```mips
    fname:		.asciiz "<name_of_file>"		# name of source file
```
- Set size of file you want to rotate in bytes in lines 17 and 31:
```mips
    img:		.space 	<size_of_file>			# size of file
```
```mips
    li          $a2, <size_of_file>				# size of file
```
- Assemble code
