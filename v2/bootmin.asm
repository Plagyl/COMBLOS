; Bootloader minimal
[org 0x7C00]
bits 16

start:
    ; Initialisation des segments
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    
    ; Afficher un message
    mov si, message
    call print
    
    ; Boucle infinie
    cli
    hlt
    jmp $

print:
    mov ah, 0x0E     ; Fonction BIOS pour télétexte
.loop:
    lodsb            ; Charge le caractère suivant dans AL
    test al, al      ; Vérifie si c'est la fin de la chaîne (0)
    jz .done         ; Si c'est la fin, on a terminé
    int 0x10         ; Appel au BIOS pour afficher le caractère
    jmp .loop        ; Boucle pour le caractère suivant
.done:
    ret

message db 'MONCOMBLE OS BOOT', 0

; Remplissage pour atteindre exactement 510 octets
times 510-($-$$) db 0

; Signature de boot (2 octets) exactement aux octets 510-511
db 0x55, 0xAA
