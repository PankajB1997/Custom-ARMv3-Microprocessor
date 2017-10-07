;----------------------------------------------------------------------------------
;--	License terms :
;--	You are free to use this code as long as you
;--		(i) DO NOT post it on any public repository;
;--		(ii) use it only for educational purposes;
;--		(iii) accept the responsibility to ensure that your implementation does not violate any intellectual property of ARM Holdings or other entities.
;--		(iv) accept that the program is provided "as is" without warranty of any kind or assurance regarding its suitability for any particular purpose;
;--		(v) send an email to rajesh.panicker@ieee.org briefly mentioning its use (except when used for the course CG3207 at the National University of Singapore);
;--		(vi) retain this notice in this file or any files derived from this.
;----------------------------------------------------------------------------------

;----------------------------------------------------------------------------------
;-- Register Glossary :
;-- R0: Stores the state of pushbutton up, i.e. BTNU
;-- R1: Stores the result of (pushbutton up state AND constant value 1) 
;-- R3: Stores a constant value of 1, used to check pushbutton state
;-- R4: Stores operand 1 taken as input
;-- R5: Stores operator taken as input
;-- R6: Stores operator 2 taken as input
;-- R7: Stores the result of the calculation given by <operand 1> <operator> <operand 2>
;-- R8: Stores the memory address of DIP Switches
;----------------------------------------------------------------------------------

	AREA    MYCODE, CODE, READONLY, ALIGN=9 
   	  ENTRY
	  
; ------- <code memory (ROM mapped to Instruction Memory) begins>
; Total number of instructions should not exceed 127 (126 excluding the last line 'halt B halt').

; Load necessary constants.
		LDR R3, ONE
		LDR R8, DIPS

; Wait for user to signal input1 is ready.
input1
		LDR R0, [R8, #4]
		ANDS R1, R0, R3, LSL #3
		BEQ input1

; Get user input.
		LDR R4, [R8]
		AND R4, R4, #255

; Wait for user to release button.
input1done
		LDR R0, [R8, #4]
		ANDS R1, R0, R3, LSL #3
		BNE input1done


; Wait for user to signal operator is ready.
operator
		LDR R0, [R8, #4]
		ANDS R1, R0, R3, LSL #3
		BEQ operator

; Get user input.
		LDR R5, [R8]
		AND R5, R5, #1

; Wait for user to release button.
operatordone
		LDR R0, [R8, #4]
		ANDS R1, R0, R3, LSL #3
		BNE operatordone


; Wait for user to signal input2 is ready.
input2
		LDR R0, [R8, #4]
		ANDS R1, R0, R3, LSL #3
		BEQ input2

; Get user input.
		LDR R6, [R8]
		AND R6, R6, #255

; Wait for user to release button.
input2done
		LDR R0, [R8, #4]
		ANDS R1, R0, R3, LSL #3
		BNE input2done


; Do the operation.
		CMP R5, #1
		BEQ addoperator
		BNE suboperator

addoperator
		ADD R7, R4, R6
		B computationdone

suboperator
		SUB R7, R4, R6

; Display result of computation on LEDS
computationdone
		STR R7, [R8, #-4]

; Loop back to input.
		B  input1


; ------- <\code memory (ROM mapped to Instruction Memory) ends>


	AREA    CONSTANTS, DATA, READONLY, ALIGN=9 
; ------- <constant memory (ROM mapped to Data Memory) begins>
; All constants should be declared in this section. This section is read only (Only LDR, no STR).
; Total number of constants should not exceed 128 (124 excluding the 4 used for peripheral pointers).
; If a variable is accessed multiple times, it is better to store the address in a register and use it rather than load it repeatedly.

;Peripheral pointers
DIPS
		DCD 0x00000C04		; Address of DIP switches. //volatile unsigned int * const DIPS = (unsigned int*)0x00000C04;

; Rest of the constants should be declared below.
ONE   
		DCD  0x1			; Constant to store 1, used for checking the pushbutton state at various points
; ------- <constant memory (ROM mapped to Data Memory) ends>	


	AREA   VARIABLES, DATA, READWRITE, ALIGN=9
; ------- <variable memory (RAM mapped to Data Memory) begins>
; All variables should be declared in this section. This section is read-write.
; Total number of variables should not exceed 128. 
; No initialization possible in this region. In other words, you should write to a location before you can read from it (i.e., write to a location using STR before reading using LDR).


; ------- <variable memory (RAM mapped to Data Memory) ends>	

		END	
