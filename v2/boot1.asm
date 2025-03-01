; boot1.asm - Premier stage du bootloader
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
    
    ; Charger le second stage à 0x8000
    mov si, loading_msg
    call print
    
    mov ax, 0x0000   ; Segment cible
    mov es, ax
    mov bx, 0x8000   ; Offset dans le segment
    
    mov ah, 0x02     ; Fonction BIOS de lecture de secteurs
    mov al, 8        ; Nombre de secteurs à lire
    mov ch, 0        ; Cylindre 0
    mov cl, 2        ; Secteur 2 (juste après le bootloader)
    mov dh, 0        ; Tête 0
    mov dl, 0x80     ; Premier disque dur
    int 0x13
    jc error
    
    ; Sauter au second stage
    mov si, jumping_msg
    call print
    jmp 0x0000:0x8000

error:
    mov si, error_msg
    call print
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

message db 'MONCOMBLE OS Stage 1', 13, 10, 0
loading_msg db 'Loading Stage 2...', 13, 10, 0
jumping_msg db 'Jumping to Stage 2...', 13, 10, 0
error_msg db 'Error loading Stage 2!', 13, 10, 0

; Remplissage pour atteindre exactement 510 octets
times 510-($-$$) db 0

; Signature de boot (2 octets) exactement aux octets 510-511
db 0x55, 0xAA
