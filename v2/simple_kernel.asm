[bits 32]
[org 0x10000]

; Point d'entrée
start:
    ; Écrire "MONCOMBLE OS BOOT OK" à 0xB8000 (mémoire vidéo)
    mov eax, 0xB8000
    mov ebx, 0x0F   ; Attribut: blanc sur fond noir
    
    ; Copier le message
    mov byte [eax], 'M'
    mov byte [eax+1], bl
    mov byte [eax+2], 'O'
    mov byte [eax+3], bl
    mov byte [eax+4], 'N'
    mov byte [eax+5], bl
    mov byte [eax+6], 'C'
    mov byte [eax+7], bl
    mov byte [eax+8], 'O'
    mov byte [eax+9], bl
    mov byte [eax+10], 'M'
    mov byte [eax+11], bl
    mov byte [eax+12], 'B'
    mov byte [eax+13], bl
    mov byte [eax+14], 'L'
    mov byte [eax+15], bl
    mov byte [eax+16], 'E'
    mov byte [eax+17], bl
    mov byte [eax+18], ' '
    mov byte [eax+19], bl
    mov byte [eax+20], 'O'
    mov byte [eax+21], bl
    mov byte [eax+22], 'S'
    mov byte [eax+23], bl
    mov byte [eax+24], ' '
    mov byte [eax+25], bl
    mov byte [eax+26], 'B'
    mov byte [eax+27], bl
    mov byte [eax+28], 'O'
    mov byte [eax+29], bl
    mov byte [eax+30], 'O'
    mov byte [eax+31], bl
    mov byte [eax+32], 'T'
    mov byte [eax+33], bl
    mov byte [eax+34], ' '
    mov byte [eax+35], bl
    mov byte [eax+36], 'O'
    mov byte [eax+37], bl
    mov byte [eax+38], 'K'
    mov byte [eax+39], bl
    
    ; Boucle infinie
    jmp $

; Padding pour atteindre au moins un secteur
times 512 - ($ - 27544) db 0
