; ----------------------------------------------------------------------------------------
; This is a x64 windows assembly program to display a simple hello world message
;   to the console using some c library functions. 
;   Use NASM to assemble the program. Then use VS linker to finish 
;   creating the executable.
; ----------------------------------------------------------------------------------------

bits 64                     ; Tell assembler we are creating a 64 bit program
default rel                 ; Set to rip, relative addressing

segment .data               ; An area for defining initialized data (variables)
    message db "Hello World!", 0xd, 0xa, 0 ; CR, LF, Null byte

segment .text               ; An area for writing assembly code
    global main             ; Export the main function/symbol
    extern ExitProcess      ; Import the ExitProcess function/symbol
    extern _CRT_INIT        ; Import the _CRT_INIT function/symbol. This is used to initialize the C runtime library

    extern printf           ; Import the C printf function

main:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    call _CRT_INIT

    lea rcx, [message]
    call printf

    xor rax, rax            ; Clear rax to zero, i.e. set it to zero
    call ExitProcess        ; Exit the program