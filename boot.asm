org 0x7c00

jmp 0:start

section .data

hello db 0xd, 0xa, 'Hello: '    ; Hello string
name times 12 db 0              ; Buffer for username
name_end equ $                  ; Username buffer ending
hello_eoln db 0xd, 0xa          ; End of line
hello_end equ $                 ; End of name section

msg db 'Enter your name:', 0xd, 0xa     ; Start information to display
msg_end equ $                           ; End of start information

backspace_code equ 0x08         ; KB - Code of backspace
enter_code equ 0x0d             ; KB - Code of enter

bootloader_size equ 446

section .text

; COPY BOOTLOADER FROM DISC TO RAM AT 0x7c00
load_bootloader:
    xor bx, bx              ; Set place to copy BL
    mov es, bx
    mov bx, 0x7c00

    xor ch, ch
    xor dh, dh
    mov al, 1
    mov cl, 2

    mov ah, 2
    mov dl, 80h

    int 13h

    jmp 0:0x7c00
 
backspace:
    cmp bx, name            ; Check if string is empty
    je reading_name

    mov ah, 0eh             ; Remove last char
    int 10h
    mov al, ' '
    int 10h
    mov al, backspace_code
    int 10h

    dec bx                  ; Move end_buffer pointer
    xor ax, ax              ; and clear buffer element
    mov [bx], ax
    jmp reading_name

accept:
    cmp bx, name+3
    jl reading_name

; Copy name to disc
    mov cx, bx
    sub cx, name
    dec cx
    xor bx, bx
move_name:
    mov ax, [name + bx]
    mov [0x600 + bx], ax

    inc bx
    cmp bx, cx
    jne move_name

    xor bx, bx              ; Set place to copy BL
    mov es, bx
    mov bx, 0x600

    xor ch, ch
    xor dh, dh
    mov al, 1
    mov cl, 3

    mov ah, 3
    mov dl, 80h

    int 13h

; Move segment resposible for coping bootloader to RAM
; To other RAM section
    xor bx, bx
copy_cb:
                            ; Read nth byte of function
    mov ax, [load_bootloader + bx]
    mov [0x600 + bx], ax    ; Save byte to other place

    inc bx                  ; Mov pointer
    cmp bx, backspace - load_bootloader
    jne copy_cb

; Show name
    mov bx, hello

write_loop:
    mov al, BYTE [bx]         ; Printing character
    mov ah, 0eh
    int 10h

    inc bx
    cmp bx, hello_end         ; Checking if buff end
    jne write_loop

    mov cx, 0xf               ; Waiting two seconds
    mov dx, 0x8480
    mov ah, 86h
    int 15h

; RUNING ORGINAL BOOTLOADER
    jmp 0:0x600

start:
; HELLO
    lea bx, [msg]

print:
    mov al, BYTE [bx]       ; Printing character from start information
    mov ah, 0eh             ; 
    int 10h 

    inc bx                  ; Increase iterator
    cmp bx, msg_end         ; Checking if buff ended
    jne print               ; Jump and print next char

; NAME
    lea bx, [name]
reading_name:
    mov ah, 10h            ; Preapare to read char
    int 16h

    cmp al, backspace_code  ; Check if backspace entered
    je backspace

    cmp al, enter_code      ; Check if enter entered
    je accept

    cmp bx, name_end        ; Check if name buffer is full
    je reading_name

    mov BYTE [bx], al       ; Set next element to given value
    mov ah, 0eh
    int 10h

    inc bx                  ; Go to next element
    jmp reading_name
