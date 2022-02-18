#####################################################################################
#
#	Name:			Barros, Mark
#	Course:			CS2640 - Computer Organization and Assembly Programming
#	Description:	This program constructs and outputs an adjacency matrix for a
#					digraph.  The graph is constructed as a word matrix.
#
#####################################################################################
#
					.data
					
header:				.asciiz			"Digraph by M. Barros\n\n"
vertices_prompt:	.asciiz			"Enter number of vertices? "
edge_prompt:		.asciiz			"Enter edge? "
					.align			2
edge:				.byte			4		# buffer for user-input edges
mat:				.word			0
				
#							
#####################################################################################
#
					.text
					
main:

		# output header
		li			$v0, 4
		la			$a0, header
		syscall

		# prompt user for number of vertices
		la			$a0, vertices_prompt
		syscall

		# accept number of vertices from user
		li			$v0, 5
		syscall
		move		$s0, $v0				# $s0 holds the number of vertices
													
		# calculate number of elements
		mul			$s1, $s0, $s0			# $s1 holds the number of elements
		
		# store matrix's base address in "mat"
		la			$t0, mat
		sw			$sp, 0($t0)
		
		# create matrix on the stack
		li			$t1, -4		
		mul			$s2, $s1, $t1			# $s2 holds required number of bytes
		add			$sp, $sp, $s2
		move		$s3, $sp				# $s3 holds first address after matrix
		addiu		$s4, $sp, 4				# $s4 holds last matrix address
		
		# populate matrix with zeros
		la			$t1, mat
		lw			$t3, 0($t1)				# $t3 is current element within matrix
		
zeros:
			
		beq			$t3, $s3, end_zeros
		sw			$zero, 0($t3)			# set current element to zero
		addiu		$t3, $t3, -4			# decrement index

		# process next element
		b			zeros

end_zeros:

		# continually prompt user for edges and add them to matrix
		
edges:		
		
		# prompt for edge
		li			$v0, 4
		la			$a0, edge_prompt
		syscall
		
		# receive edge
		li			$v0, 8
		la			$a0, edge
		li			$a1, 4
		syscall		
	
		# retrieve "from" and "to" vertices
		la			$t0, edge
		lb			$a2, 0($t0)			# $a2 is "from" vertex
		lb			$a3, 1($t0)			# $a3 is "to" vertex
		
		# if user inputs only "X" then exit loop
		li			$t1, 'X'
		li			$t2, '\n'
		bne			$a2, $t1, end_check
		beq			$a3, $t2, end_edges
		
end_check:		
		
		# prepare arguments for "addedge" call
		la			$t1, mat
		lw			$a0, 0($t1)			# $a0 is address of the matrix			
		move		$a1, $s0			# $a1 is number of rows/columns
		sub			$a2, 'A'			# $a2 is row index
		sub			$a3, 'A'			# $a3 is column index
		
		# add edge to matrix		
		jal			addedge
		
		# process next edge		
		b			edges
		
end_edges:		

		# prepare arguments for "print" call
		la			$t1, mat
		lw			$a0, 0($t1)			# $a0 is matrix's address
		move		$a1, $s0			# $a1 is number of rows
		move		$a2, $s0			# $a2 is number of columns
		
		# output matrix to the console
		jal			print

		# output a new line
		li				$v0, 11
		li				$a0, '\n'
		syscall
		
		# exit program
		li			$v0, 10
		syscall
#
#####################################################################################
#
#	addedge($a0, $a1, $a2, $a3)
# 		add an edge to the matrix
#	parameters:
#		$a0: points to the matrix
#		$a1: number of columns
#		$a2: "from" node
#		$a3: "to" node
#

addedge:

		# save return address of main onto the stack
		addiu		$sp, $sp, -4		
		sw			$ra, 0($sp)

		# get effective address
		jal			getae
		
		# set element of effective address to value of one
		li			$t0, 1
		sw			$t0, 0($v0)
		
		# return to main
		lw			$ra, 0($sp)
		addiu		$sp, $sp, 4	
		jr			$ra
#
#####################################################################################
#
#	getae($a0, $a1, $a2, $a3)
# 		computes the effective address
#	parameters:
#		$a0: matrix's address
#		$a1: number of columns
#		$a2: row index
#		$a3: column index
#	return:
#		$v0: effective address
#	

getae:
		
		# compute effective address (base address + offset)					
		mul			$t0, $a2, $a1			# $t0 = row * number_of_rows
		add			$t0, $t0, $a3			# $t0 + column
		sll			$t0, $t0, 2				# account for data-type size (word)
		sub			$a0, $a0, $t0			# subtract offset ($t0) from base address ($s0)	
		move		$v0, $a0				# return effective address
		
		# return to "addedge"
		jr			$ra
#				
#####################################################################################
#
#	print($a0, $a1, $a3)
# 		output the matrix
#	parameters:
#		$a0: matrix's address
#		$a1: number of rows
#		$a2: number of columns
#

print:

		# save arguments
		move			$s5, $a0				# $s5 is matrix's address
		move			$s6, $a1				# $s6 is number of rows
		move			$s7, $a2				# $s7 is number of columns
	
		# set first and last column headers
		li				$t0, 'A' 				# first column label ("A")
		li				$t1, 'A' 				# setting last column label
		add				$t1, $t1, $s7			#	"		"		"
		addi			$t1, $t1, -1			#	"		"		"
	
		# initialize looping variables
		move			$t5, $s5				# $t5 is current address
		move			$t7, $s7				# $t7 is last column
		move			$t8, $zero				# $t8 is column index
	
		# output initial column header
		li				$v0, 11
		li				$a0, '\n'
		syscall
	
		li				$a0, '*'
		syscall
	
		li				$a0, ' '
		syscall
	
		# output column headers
		
column_h:
	
		# exit loop when column label equals last column label
		bgt				$t0, $t1, end_column_h
	
		# output current column label
		move			$a0, $t0				
		syscall
	
		# output space
		li				$a0, ' '				
		syscall
	
		# increment column label
		add				$t0, 1					
	
		# process next column label
		b				column_h
	
end_column_h:

		# set first and last row headers
		li				$t0, 'A'				# set first row label
		li				$t1, 'A'				# set last row label
		add				$t1, $t1, $s6			#	"		"		"
		addi			$t1, $t1, -1			#	"		"		"
	
		# output row headers
		
row_h:
	
		# exit loop when row label equals last row label
		bgt				$t0, $t1, end_row_h
	
		# output new line
		li				$v0, 11
		li				$a0, '\n'
		syscall
	
		# output current row label
		move			$a0, $t0
		syscall
	
		# output blank space
		li				$a0, ' '
		syscall
	
		# output matrix
		
column_out:
	
		# exit loop when at end of row
		beq			$t8, $t7, end_column_out
		
		# output current element to console 
		lw			$a0, 0($t5)
		li			$v0, 1
		syscall
			
		# output a blank space
		li			$a0, ' '
		li			$v0, 11
		syscall
		
		# increment both current address and column index
		addiu		$t5, -4
		addi		$t8, 1
		
		# output next column
		b			column_out
		
end_column_out:

		# reset column index to zero
		move			$t8, $zero				
	
		# increment row label
		add				$t0, 1					
	
		# output next row header
		b				row_h
	
end_row_h:
	
		# return to main
		jr				$ra
#
#####################################################################################