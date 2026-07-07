
;  =============================================================================
;  - mov destination, source : Copies data from source to destination.
;  - cmp value1, value2      : Compares two values by subtracting them.
;  - je label                : Jump to "label" if the compared values were equal.
;  - jne label               : Jump to "label" if the compared values were NOT equal.
;  - jle label               : Jump to "label" if value1 is less than or equal to value2.
;  - jg label                : Jump to "label" if value1 is greater than value2.
;  - jmp label               : Jump to "label" instantly without any conditions.
;  - inc register            : Adds 1 to the register (e.g. ECX = ECX + 1).
;  - dec register            : Subtracts 1 from the register (e.g. ECX = ECX - 1).
;  - loop label              : Decrements ECX automatically. If ECX is not 0, loops back.
;  - push register           : Temporarily saves a register's value on the stack.
;  - pop register            : Restores the saved value from the stack back into a register.
;  - call procedure          : Jumps to and runs a block of code (procedure).
;  - ret                     : Returns back from a procedure to where it was called.
;  - offset variable         : Gets the memory address (pointer) of a variable.
;  - [register]              : Dereferences a pointer to read the data inside that address.
;  - movzx destination, src  : Moves small data (e.g. byte) to larger register (e.g. 32-bit),
;                              padding the rest with zeros so we don't have garbage data.
;
;  =============================================================================
;  ** CPU REGISTERS CHEAT SHEET **
;  =============================================================================
;  - EAX: Accumulator Register (general purpose, holds function return values).
;  - EBX: Base Register (used to hold array indices or address bases).
;  - ECX: Counter Register (automatically used by loops as a countdown timer).
;  - EDX: Data Register (used to pass string addresses to WriteString).
;  - ESI: Source Index (used as a pointer to read letters from arrays/strings).
;  - EDI: Destination Index (used as a pointer to write letters to arrays/strings).
; ==============================================================================

INCLUDE Irvine32.inc

; ==============================================================================
;  CONSTANTS SEGMENT (Fixed settings that never change during run-time)
; ==============================================================================
MAX_WRONG   EQU 6          ; Maximum incorrect guesses allowed before losing
WORD_COUNT  EQU 8          ; Total number of secret words in our dictionary

; ==============================================================================
;  DATA SEGMENT (All variables, string messages, and tables are stored here)
; ==============================================================================
.data

; ---------- Secret Word List (Each word ends with 0 to indicate string end) ---
word0   BYTE "ASSEMBLY",0
word1   BYTE "COMPUTER",0
word2   BYTE "PROGRAM",0
word3   BYTE "KEYBOARD",0
word4   BYTE "MONITOR",0
word5   BYTE "NETWORK",0
word6   BYTE "IRVINE",0
word7   BYTE "WINDOWS",0

; ---------- Table of pointers holding addresses to each word in our list -----
wordTable DWORD OFFSET word0, OFFSET word1, OFFSET word2,
               OFFSET word3, OFFSET word4, OFFSET word5,
               OFFSET word6, OFFSET word7

; ---------- Hint List (Each hint corresponds to the word with the same index) --
hint0   BYTE "A low-level programming language for the CPU",0
hint1   BYTE "An electronic device that processes data",0
hint2   BYTE "A set of instructions that a computer executes",0
hint3   BYTE "An input device used for typing",0
hint4   BYTE "An output device that displays graphics/text",0
hint5   BYTE "A group of interconnected computers",0
hint6   BYTE "The author of the x86 library we are using",0
hint7   BYTE "A popular operating system developed by Microsoft",0

; ---------- Table of pointers holding addresses to each hint in our list -----
hintTable DWORD OFFSET hint0, OFFSET hint1, OFFSET hint2,
               OFFSET hint3, OFFSET hint4, OFFSET hint5,
               OFFSET hint6, OFFSET hint7

; ---------- Game State Variables --------------------------------------------
currentWord   DWORD  ?        ; Points to the memory address of the chosen word
currentHint   DWORD  ?        ; Points to the memory address of the chosen hint
wordLen       DWORD  ?        ; Stores the length of the chosen word (number of letters)
wrongCount    DWORD  0        ; Counts how many incorrect guesses the player has made
guessedMask   BYTE   26 DUP(0) ; 26-slot array (A-Z). 1 = already guessed, 0 = not guessed
displayWord   BYTE   20 DUP('_'), 0 ; The blank underscores shown to the player (e.g. "___")

; ---------- String Messages (Null-terminated text printed to the console) ---
msgWelcome    BYTE  "========================================",13,10
              BYTE  "        HANGMAN GAME - IRVINE32        ",13,10
              BYTE  "========================================",13,10,0
msgGuess      BYTE  13,10,"Enter a letter to guess (A-Z): ",0
msgWrong      BYTE  "Incorrect! :( ",0
msgCorrect    BYTE  "Correct! :) ",0
msgAlready    BYTE  "You have already guessed this letter!",13,10,0
msgWin        BYTE  13,10,"** CONGRATULATIONS! You won the game! **",13,10,0
msgLose       BYTE  13,10,"** GAME OVER! The correct word was: ",0
msgWrongLeft  BYTE  "Guesses remaining: ",0
msgWord       BYTE  "Word: ",0
msgHint       BYTE  "Hint: ",0
msgGuesses    BYTE  "Incorrect Guesses: ",0
msgNewLine    BYTE  13,10,0
msgPlayAgain  BYTE  13,10,"Would you like to play again? (Y/N): ",0

; ---------- Hangman gallows ASCII Art drawings (Stages 0 to 6) ---------------
hang0   BYTE "  +---+  ",13,10
        BYTE "  |   |  ",13,10
        BYTE "  |      ",13,10
        BYTE "  |      ",13,10
        BYTE "  |      ",13,10
        BYTE " ===     ",13,10,0

hang1   BYTE "  +---+  ",13,10
        BYTE "  |   |  ",13,10
        BYTE "  |   O  ",13,10
        BYTE "  |      ",13,10
        BYTE "  |      ",13,10
        BYTE " ===     ",13,10,0

hang2   BYTE "  +---+  ",13,10
        BYTE "  |   |  ",13,10
        BYTE "  |   O  ",13,10
        BYTE "  |   |  ",13,10
        BYTE "  |      ",13,10
        BYTE " ===     ",13,10,0

hang3   BYTE "  +---+  ",13,10
        BYTE "  |   |  ",13,10
        BYTE "  |   O  ",13,10
        BYTE "  |  /|  ",13,10
        BYTE "  |      ",13,10
        BYTE " ===     ",13,10,0

hang4   BYTE "  +---+  ",13,10
        BYTE "  |   |  ",13,10
        BYTE "  |   O  ",13,10
        BYTE "  |  /|\ ",13,10
        BYTE "  |      ",13,10
        BYTE " ===     ",13,10,0

hang5   BYTE "  +---+  ",13,10
        BYTE "  |   |  ",13,10
        BYTE "  |   O  ",13,10
        BYTE "  |  /|\ ",13,10
        BYTE "  |  /   ",13,10
        BYTE " ===     ",13,10,0

hang6   BYTE "  +---+  ",13,10
        BYTE "  |   |  ",13,10
        BYTE "  |   O  ",13,10
        BYTE "  |  /|\ ",13,10
        BYTE "  |  / \ ",13,10
        BYTE " ===     ",13,10,0

; ---------- Table holding addresses of each ASCII stage drawing for quick index --
hangTable DWORD OFFSET hang0, OFFSET hang1, OFFSET hang2,
                OFFSET hang3, OFFSET hang4, OFFSET hang5,
                OFFSET hang6

; ==============================================================================
;  CODE SEGMENT (All instructions and logic procedures are defined here)
; ==============================================================================
.code

; ------------------------------------------------------------------------------
;  PROCEDURE: PrintStr
;  PURPOSE: Prints a null-terminated string to the console screen
;  INPUT: EDX = holds the memory offset of the string to print
; ------------------------------------------------------------------------------
PrintStr PROC
    call WriteString              ; Irvine32 routine to print string located at EDX
    ret                           ; Return back to where we called it
PrintStr ENDP

; ------------------------------------------------------------------------------
;  PROCEDURE: PrintCRLF
;  PURPOSE: Moves cursor to a new line on the screen
; ------------------------------------------------------------------------------
PrintCRLF PROC
    mov  edx, OFFSET msgNewLine   ; EDX = memory address of our newline character code
    call WriteString              ; Print it
    ret                           ; Return to the caller
PrintCRLF ENDP

; ------------------------------------------------------------------------------
;  PROCEDURE: DrawHangman
;  PURPOSE: Draws the hangman ASCII gallows stage corresponding to wrongCount
; ------------------------------------------------------------------------------
DrawHangman PROC
    mov  eax, wrongCount          ; Copy our current wrongCount value into EAX
    cmp  eax, MAX_WRONG           ; Compare wrongCount with 6 (maximum allowed)
    jle  @validStage              ; If wrongCount is <= 6, it is a valid stage index!
    mov  eax, MAX_WRONG           ; If wrongCount > 6, cap it at 6 to prevent memory errors

@validStage:
    mov  esi, OFFSET hangTable    ; Point ESI to the start of our hangTable array
    mov  edx, [esi + eax*4]       ; Multiply stage index by 4 (pointers are 4 bytes) and load drawing address into EDX
    call WriteString              ; Irvine32 prints the drawing pointed to by EDX
    ret                           ; Return to caller
DrawHangman ENDP

; ------------------------------------------------------------------------------
;  PROCEDURE: ShowDisplayWord
;  PURPOSE: Displays the secret word with blanks and spacing (e.g., "A _ _ E M _ L _")
; ------------------------------------------------------------------------------
ShowDisplayWord PROC
    mov  edx, OFFSET msgWord      ; EDX = pointer to "Word: " string
    call WriteString              ; Print "Word: "

    ; Initialize loop pointers and counter
    mov  esi, OFFSET displayWord  ; ESI = points to displayWord array (which holds underscores/letters)
    mov  ecx, wordLen             ; ECX = length of secret word (loop counter)

@printLoop:
    movzx eax, BYTE PTR [esi]     ; Load one character from displayWord into EAX and clear extra bits
    call  WriteChar               ; Print the character
    mov  al, ' '                  ; AL = space character
    call WriteChar                ; Print a space to separate letters nicely
    inc  esi                      ; Advance ESI pointer to the next character in displayWord
    loop @printLoop               ; Automatically decrements ECX. If ECX is not 0, repeat loop!

    call PrintCRLF                ; Print a newline at the end
    ret                           ; Return to caller
ShowDisplayWord ENDP

; ------------------------------------------------------------------------------
;  PROCEDURE: ShowHint
;  PURPOSE: Prints the hint for the current secret word
; ------------------------------------------------------------------------------
ShowHint PROC
    mov  edx, OFFSET msgHint      ; EDX = pointer to "Hint: " string
    call WriteString              ; Print "Hint: "
    mov  edx, currentHint         ; EDX = pointer to the current secret word's hint
    call WriteString              ; Print the actual hint text
    call PrintCRLF                ; Print a newline for clean layout spacing
    ret                           ; Return to caller
ShowHint ENDP

; ------------------------------------------------------------------------------
;  PROCEDURE: ShowGuessedLetters
;  PURPOSE: Loops through letters A-Z to print all incorrect guessed letters
; ------------------------------------------------------------------------------
ShowGuessedLetters PROC
    mov  edx, OFFSET msgGuesses   ; EDX = pointer to "Incorrect Guesses: " string
    call WriteString              ; Print it

    mov  ecx, 26                  ; ECX = 26 (we want to check all 26 letters 'A'-'Z')
    mov  esi, OFFSET guessedMask   ; ESI = pointer to start of our guessedMask array
    mov  ebx, 'A'                 ; EBX = start character is 'A' (ASCII 65)

@checkLoop:
    cmp  BYTE PTR [esi], 1        ; Check if this letter has been guessed (1 = yes, 0 = no)
    jne  @skip                    ; If it has not been guessed, skip to next letter

    ; Save loop registers on stack so they don't get modified by inner operations
    push ecx                      ; Save outer loop counter
    push esi                      ; Save outer array pointer
    push ebx                      ; Save current character 'A'-'Z'

    ; Check if this guessed letter is correct (exists inside displayWord)
    ; If it is correct, we do NOT print it here because we only print WRONG guesses
    mov  edi, OFFSET displayWord  ; EDI = pointer to start of displayWord
    mov  ecx, wordLen             ; ECX = secret word length
    mov  al, bl                   ; AL = current character we are checking

@innerLoop:
    cmp  [edi], al                ; Compare displayWord character with our character
    je   @inWord                  ; If they match, it was a correct guess! Jump to @inWord
    inc  edi                      ; Move EDI to next letter in displayWord
    loop @innerLoop               ; Decrement ECX, repeat until word is fully scanned

    ; If we finished the inner loop without jumping, it's an incorrect guess. Print it!
    mov  al, bl                   ; AL = wrong letter
    call WriteChar                ; Print it
    mov  al, ' '                  ; AL = space character
    call WriteChar                ; Print space separator
    jmp  @afterShow               ; Done printing, go to pop registers

@inWord:
    ; It was a correct guess. Do nothing (don't print it).

@afterShow:
    pop  ebx                      ; Restore original current character
    pop  esi                      ; Restore original array pointer
    pop  ecx                      ; Restore original loop counter

@skip:
    inc  esi                      ; Advance ESI to next slot in guessedMask array
    inc  ebx                      ; Advance character to next letter (e.g. 'A' -> 'B')
    loop @checkLoop               ; Decrement ECX, repeat outer loop if ECX is not 0

    call PrintCRLF                ; Print a newline at the end
    ret                           ; Return to caller
ShowGuessedLetters ENDP

; ------------------------------------------------------------------------------
;  PROCEDURE: ChooseWord
;  PURPOSE: Randomly chooses a secret word and prepares underscores for guessing
; ------------------------------------------------------------------------------
ChooseWord PROC
    call Randomize                ; Seed the random generator with system clock
    mov  eax, WORD_COUNT          ; EAX = 8 (Range limit for random number)
    call RandomRange              ; Returns a random number between 0 and 7 in EAX
    
    ; Lookup the selected word's address in our wordTable using index EAX
    mov  esi, OFFSET wordTable    ; ESI = start address of our wordTable array
    mov  esi, [esi + eax*4]       ; Multiply index by 4 (addresses are 4 bytes) and load chosen word address to ESI
    mov  currentWord, esi         ; Save this address in currentWord pointer variable

    ; Save the index in EAX on the stack so it isn't lost during word length calculation
    push eax                      

    ; Count characters to calculate secret word length
    push esi                      ; Temporarily save ESI (chosen word address) on stack
    xor  ecx, ecx                 ; ECX = 0 (this will count our letters)

@lenLoop:
    cmp  BYTE PTR [esi], 0        ; Is the current character 0 (null-terminator)?
    je   @lenDone                 ; Yes, we hit the end! Jump to @lenDone
    inc  esi                      ; Move ESI pointer to the next letter
    inc  ecx                      ; Increment our counter by 1
    jmp  @lenLoop                 ; Repeat loop

@lenDone:
    mov  wordLen, ecx             ; Save letter count in wordLen variable
    pop  esi                      ; Restore original word address into ESI

    ; Initialize displayWord with underscores '_' (e.g. DOG -> "___")
    mov  edi, OFFSET displayWord  ; EDI = pointer to start of displayWord array
    mov  ecx, wordLen             ; ECX = length of secret word (loop counter)

@initBlanks:
    mov  BYTE PTR [edi], '_'      ; Put an underscore character in memory at EDI
    inc  edi                      ; Move EDI to next slot
    loop @initBlanks              ; Decrement ECX, repeat until all blanks are written

    mov  BYTE PTR [edi], 0        ; Write a null-terminator (0) at the end to make it a valid string

    ; Restore our index back to EAX from stack
    pop  eax                      

    ; Lookup the selected hint's address in our hintTable using index EAX
    mov  esi, OFFSET hintTable    ; ESI = start address of our hintTable array
    mov  esi, [esi + eax*4]       ; Multiply index by 4 and load chosen hint address to ESI
    mov  currentHint, esi         ; Save this address in currentHint pointer variable

    ret                           ; Return to caller
ChooseWord ENDP

; ------------------------------------------------------------------------------
;  PROCEDURE: ResetGame
;  PURPOSE: Resets game counters and clears arrays to start a new round
; ------------------------------------------------------------------------------
ResetGame PROC
    mov  wrongCount, 0            ; Set wrongCount = 0 (reset incorrect guesses)

    ; Clear guessedMask array back to zeros (26 bytes total, one for each letter A-Z)
    mov  edi, OFFSET guessedMask   ; EDI = pointer to start of guessedMask
    mov  ecx, 26                  ; ECX = 26 (clear 26 slots)
    xor  al, al                   ; AL = 0

@clearMask:
    mov  [edi], al                ; Set current array element to 0
    inc  edi                      ; Move to next element in array
    loop @clearMask               ; Repeat 26 times

    call ChooseWord               ; Pick a new word and setup underscores
    ret                           ; Return to caller
ResetGame ENDP

; ------------------------------------------------------------------------------
;  PROCEDURE: CheckWin
;  PURPOSE: Checks if displayWord has any underscores left
;  RETURNS: EAX = 1 if player won (no underscores left), EAX = 0 if not won yet
; ------------------------------------------------------------------------------
CheckWin PROC
    mov  esi, OFFSET displayWord  ; ESI = pointer to start of displayWord array
    mov  ecx, wordLen             ; ECX = length of secret word

@winLoop:
    cmp  BYTE PTR [esi], '_'      ; Is this character an underscore?
    je   @notWon                  ; Yes, they haven't finished! Jump to @notWon
    inc  esi                      ; Move to next character in displayWord
    loop @winLoop                 ; Decrement ECX, repeat if not completed

    ; No underscores found! Player won!
    mov  eax, 1                   ; EAX = 1 (Win status code)
    ret                           ; Return to caller

@notWon:
    xor  eax, eax                 ; EAX = 0 (Not won status code)
    ret                           ; Return to caller
CheckWin ENDP

; ------------------------------------------------------------------------------
;  PROCEDURE: ProcessGuess
;  INPUT: AL = Guessed uppercase letter (e.g., 'E')
;  RETURNS: EAX = 1 (Win), EAX = 2 (Lose), EAX = 0 (Keep playing)
; ------------------------------------------------------------------------------
ProcessGuess PROC
    ; 1. Convert letter A-Z to an index 0-25 (A=0, B=1, C=2...)
    movzx ebx, al                 ; Copy letter from AL into EBX and pad rest with 0s
    sub  ebx, 'A'                 ; Subtract ASCII value of 'A' (65). EBX now has 0 to 25 index

    ; 2. Check if letter has already been guessed
    cmp  BYTE PTR [guessedMask + ebx], 1 ; Is guessedMask[index] already 1?
    jne  @newGuess                ; No, it's a new guess! Jump to @newGuess

    ; Letter already tried branch
    mov  edx, OFFSET msgAlready   ; EDX = pointer to "You already guessed this letter" string
    call WriteString              ; Print warning message
    xor  eax, eax                 ; EAX = 0 (Continue playing status)
    ret                           ; Return to caller

@newGuess:
    ; 3. Mark letter as guessed
    mov  BYTE PTR [guessedMask + ebx], 1 ; Mark guessedMask[index] = 1

    ; 4. Scan secret word to search for matched letter
    mov  esi, currentWord         ; ESI = points to start of secret word
    mov  edi, OFFSET displayWord  ; EDI = points to start of displayWord
    mov  ecx, wordLen             ; ECX = length of secret word
    mov  bl, al                   ; BL = store letter we are searching for
    xor  edx, edx                 ; EDX = 0 (Found Flag: 0 = not found, 1 = found)

@searchLoop:
    cmp  [esi], bl                ; Compare secret word character with guessed letter
    jne  @nextChar                ; If no match, skip to next character
    mov  [edi], bl                ; MATCH! Write letter into displayWord at matching position
    mov  edx, 1                   ; Set Found Flag to 1

@nextChar:
    inc  esi                      ; Move ESI to next char in secret word
    inc  edi                      ; Move EDI to next char in displayWord
    loop @searchLoop              ; Decrement ECX, repeat loop until all chars are checked

    ; 5. Was the guessed letter correct?
    cmp  edx, 1                   ; Check if Found Flag is 1
    je   @letterFound             ; Yes! Jump to @letterFound

    ; --- INCORRECT GUESS BRANCH ---
    inc  wrongCount               ; Increment wrongCount by 1
    mov  edx, OFFSET msgWrong     ; EDX = pointer to "Incorrect!" string
    call WriteString              ; Print it

    mov  edx, OFFSET msgWrongLeft ; EDX = pointer to "Guesses remaining: " string
    call WriteString              ; Print it

    ; Calculate and show remaining chances: MAX_WRONG (6) - wrongCount
    mov  eax, MAX_WRONG           ; EAX = 6
    sub  eax, wrongCount          ; EAX = 6 - wrongCount
    call WriteDec                 ; Irvine32 prints the integer in EAX
    call PrintCRLF                ; Print newline

    ; Check if maximum wrong attempts reached
    cmp  wrongCount, MAX_WRONG    ; Is wrongCount >= 6?
    jge  @lose                    ; Yes, they ran out of tries! Jump to @lose
    
    xor  eax, eax                 ; No, they still have chances left. EAX = 0 (Keep playing)
    ret                           ; Return to caller

@letterFound:
    ; --- CORRECT GUESS BRANCH ---
    mov  edx, OFFSET msgCorrect   ; EDX = pointer to "Correct!" string
    call WriteString              ; Print it
    call PrintCRLF                ; Print newline

    ; Check if displayWord is fully revealed
    call CheckWin                 ; Call CheckWin (returns 1 in EAX if won, 0 if not)
    cmp  eax, 1                   ; Did player win?
    je   @win                     ; Yes! Jump to @win
    
    xor  eax, eax                 ; No, not won yet. EAX = 0 (Keep playing)
    ret                           ; Return to caller

@win:
    mov  eax, 1                   ; EAX = 1 (Win status code)
    ret                           ; Return to caller

@lose:
    mov  eax, 2                   ; EAX = 2 (Lose status code)
    ret                           ; Return to caller
ProcessGuess ENDP

; ------------------------------------------------------------------------------
;  PROCEDURE: GetUpperLetter
;  PURPOSE: Reads a letter from keyboard, converts lowercase to uppercase, validates A-Z
;  RETURNS: AL = uppercase validated letter
; ------------------------------------------------------------------------------
GetUpperLetter PROC
@inputLoop:
    mov  edx, OFFSET msgGuess     ; EDX = pointer to guess prompt string
    call WriteString              ; Print "Enter a letter to guess (A-Z): "
    call ReadChar                 ; Irvine32 reads keypress into AL (doesn't echo automatically)
    call WriteChar                ; Print the character they typed on screen
    call PrintCRLF                ; Print newline

    ; Convert lowercase letters ('a'-'z') to uppercase
    cmp  al, 'a'                  ; Is char < 'a'?
    jl   @checkUpper              ; Yes, it cannot be lowercase. Skip to validation
    cmp  al, 'z'                  ; Is char > 'z'?
    jg   @checkUpper              ; Yes, it cannot be lowercase. Skip to validation
    sub  al, 32                   ; Convert to uppercase (subtracting 32 from lowercase ASCII gives uppercase)

@checkUpper:
    ; Validate that character is now in range 'A' to 'Z'
    cmp  al, 'A'                  ; Is char < 'A'?
    jl   @inputLoop               ; Invalid symbol! Loop back to ask again
    cmp  al, 'Z'                  ; Is char > 'Z'?
    jg   @inputLoop               ; Invalid symbol! Loop back to ask again
    
    ret                           ; Return to caller with valid uppercase letter in AL
GetUpperLetter ENDP

; ------------------------------------------------------------------------------
;  MAIN ENTRY PROCEDURE
; ------------------------------------------------------------------------------
main PROC
    call Clrscr                   ; Clear screen on start

@newGame:
    call ResetGame                ; Reset game state variables and select a secret word

@gameLoop:
    call Clrscr                   ; Clear screen to draw updated game view
    mov  edx, OFFSET msgWelcome   ; EDX = pointer to welcome banner string
    call WriteString              ; Print welcome banner

    call DrawHangman              ; Draw the current Hangman ASCII art
    call PrintCRLF                ; Spacing newline
    call ShowDisplayWord          ; Display underscores and correctly guessed letters
    call ShowHint                 ; Display the hint for the chosen word
    call ShowGuessedLetters       ; Display list of incorrect guessed letters

    call GetUpperLetter           ; Read keyboard and return a valid letter in AL

    call ProcessGuess             ; Process the letter (returns 0=continue, 1=win, 2=lose in EAX)
    cmp  eax, 1                   ; Player won?
    je   @playerWon               ; Yes! Jump to win screen
    cmp  eax, 2                   ; Player lost?
    je   @playerLost              ; Yes! Jump to lose screen
    jmp  @gameLoop                ; If status is 0, repeat game loop to play next round

@playerWon:
    ; Win screen rendering
    call Clrscr                   
    mov  edx, OFFSET msgWelcome   
    call WriteString              
    call DrawHangman              
    call PrintCRLF                
    call ShowDisplayWord          
    mov  edx, OFFSET msgWin        ; EDX = pointer to congratulations message
    call WriteString              ; Print it
    jmp  @askPlayAgain            ; Jump to play again prompt

@playerLost:
    ; Lose screen rendering
    call Clrscr                   
    call DrawHangman              
    call PrintCRLF                
    mov  edx, OFFSET msgLose       ; EDX = pointer to "GAME OVER!" message
    call WriteString              ; Print it
    
    mov  esi, currentWord         ; ESI = secret word pointer
    mov  edx, esi                 ; EDX = copy pointer to EDX
    call WriteString              ; Print the secret word so they see what they missed
    call PrintCRLF                ; Spacing newline

@askPlayAgain:
    mov  edx, OFFSET msgPlayAgain ; EDX = pointer to "Play again? (Y/N): " string
    call WriteString              ; Print it
    call ReadChar                 ; Read keyboard input character into AL
    call WriteChar                ; Echo input character
    call PrintCRLF                ; Print newline

    cmp  al, 'Y'                  ; Typed 'Y'?
    je   @newGame                 ; Restart game!
    cmp  al, 'y'                  ; Typed 'y'?
    je   @newGame                 ; Restart game!

    ; If they typed anything else, close the game
    call WaitMsg                  ; Print Irvine32 default exit prompt and wait for a keypress
    exit                          ; Terminate assembly program execution
main ENDP
END main
