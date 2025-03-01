; test_times.asm
[org 0x7C00]

; Version 1 (sans espaces)
times 10 db 0

; Version 2 (avec espaces)
times 10 db 0

; Version 3 (avec parenthèses)
times (10) db 0

; Version 4 (expression simple)
times 5+5 db 0

; Version 5 (expression avec variable)
count equ 10
times count db 0

; Version 6 (expression avec $)
start:
    jmp $
times 510-($-$$) db 0
dw 0xAA55
