; ----------------------------------------------------------------------------------------
; This is a x64 windows assembly program to display a simple hello world message
;   to the console using only OS function calls (WinAPI / Kernel32.dll). 
;   Use NASM to assemble the program. Then use VS linker to finish 
;   creating the executable.
; ----------------------------------------------------------------------------------------

bits 64                             ; Tell assembler we are creating a 64 bit program
default rel                         ; Set to rip, relative addressing

STD_OUTPUT_HANDLE   equ -11
NULL                equ 0

segment .data                       ; An area for defining initialized data (variables)
    

    message db "Hello World!", 0xd, 0xa, 0 ; CR, LF, Null byte
    messageLength       equ $-message      ; Length of 'message' string

segment .text                       ; An area for writing assembly code
    global _start                   ; Export the _start function/symbol
    extern GetStdHandle             ; Import the GetStdHandle function/symbol (kernel32.dll)
    extern WriteConsoleA            ; Import the WriteConsoleA function/symbol (kernel32.dll)

    extern ExitProcess              ; Import the ExitProcess function/symbol (kernel32.dll)

_start:
    ; At _start the stack is 8 bytes misaligned because there is a return
    ; address to the MSVCRT runtime library on the stack.
    ; 8 bytes of temporary storage for `numCharsWritten`.
    ; allocate 32 bytes of stack for shadow space.
    ; 8 bytes for the 5th parameter of WriteConsole.
    ; An additional 8 bytes for padding to make RSP 16 byte aligned.
    sub rsp, 8+8+8+32
    ; At this point RSP is aligned on a 16 byte boundary and all necessary
    ; space has been allocated.


    ; hStdOut = GetStdHandle(STD_OUTPUT_HANDLE)
    mov ecx, STD_OUTPUT_HANDLE
    call GetStdHandle

    ; WriteConsoleA(handle, buffer, bufferLength, &numCharsWritten, NULL)
    mov rcx, rax
    mov rdx, message
    mov r8, messageLength
    lea r9, [rsp-16]                ; Address for `numCharsWritten`
    ; RSP-17 through RSP-48 are the 32 bytes of shadow space
    mov qword [rsp-56], 0           ; First stack parameter of WriteConsoleA function
    call WriteConsoleA

    ;xor rax, rax                   ; Clear rax to zero, i.e. set it to zero
    ;call ExitProcess               ; Exit the program

    add rsp, 8+8+32+8               ; Restore the stack pointer.
    xor eax, eax                    ; RAX = return value = 0
    ret