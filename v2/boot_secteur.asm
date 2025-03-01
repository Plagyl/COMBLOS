; ============================================================================
; boot_secteur.asm -- Bootloader ultra-simplifié
; ============================================================================
[org 0x7C00]
bits 16

; Code principal
start:
    ; Configuration des segments
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    
    ; Afficher un message
    mov si, hello_msg
    call print_string
    
    ; Charger le kernel directement depuis le secteur 2
    mov ax, 0x1000   ; Segment où charger
    mov es, ax
    xor bx, bx       ; Offset où charger (ES:BX = 0x1000:0x0000 = 0x10000)
    
    mov ah, 0x02     ; Fonction BIOS de lecture de secteurs
    mov al, 32       ; Nombre de secteurs à lire
    mov ch, 0        ; Cylindre 0
    mov cl, 2        ; Secteur 2 (secteurs numérotés à partir de 1)
    mov dh, 0        ; Tête 0
    mov dl, 0x80     ; Premier disque dur
    int 0x13
    jc disk_error
    
    ; Message de succès
    mov si, success_msg
    call print_string
    
    ; Passage en mode protégé et saut vers le kernel
    cli              ; Désactiver les interruptions
    lgdt [gdt_descriptor]
    
    ; Activer le bit de mode protégé
    mov eax, cr0
    or al, 1
    mov cr0, eax
    
    ; Saut vers le code 32 bits
    jmp CODE_SEG:protected_mode

disk_error:
    mov si, error_msg
    call print_string
    cli
    hlt

; Fonction pour afficher une chaîne de caractères
print_string:
    pusha
    mov ah, 0x0E
.loop:
    lodsb
    test al, al
    jz .done
    int 0x10
    jmp .loop
.done:
    popa
    ret

; ---- Mode protégé ----
[bits 32]
protected_mode:
    ; Initialiser les segments de données
    mov ax, DATA_SEG
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    
    ; Initialiser la pile
    mov ebp, 0x90000
    mov esp, ebp
    
    ; Sauter vers le kernel en 0x10000
    jmp 0x10000

; ---- Global Descriptor Table ----
gdt_start:
    ; Descripteur NULL
    dq 0x0
    
    ; Descripteur de code (0x08)
    dw 0xFFFF    ; Limite (bits 0-15)
    dw 0x0       ; Base (bits 0-15)
    db 0x0       ; Base (bits 16-23)
    db 10011010b ; Flags d'accès
    db 11001111b ; Flags + Limite (bits 16-19)
    db 0x0       ; Base (bits 24-31)
    
    ; Descripteur de données (0x10)
    dw 0xFFFF    ; Limite (bits 0-15)
    dw 0x0       ; Base (bits 0-15)
    db 0x0       ; Base (bits 16-23)
    db 10010010b ; Flags d'accès
    db 11001111b ; Flags + Limite (bits 16-19)
    db 0x0       ; Base (bits 24-31)
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1  ; Taille de la GDT moins 1
    dd gdt_start                ; Adresse de la GDT

; Définitions pour faciliter le code
CODE_SEG equ 0x08
DATA_SEG equ 0x10

; ---- Données ----
hello_msg db 'MONCOMBLE_OS Bootloader', 13, 10, 0
success_msg db 'Kernel charge! Passage en mode protege...', 13, 10, 0
error_msg db 'Erreur de lecture disque!', 13, 10, 0

; ---- Padding et signature ----
; Calcul de l'espace à remplir
padding_size equ 510 - ($ - $$)
; Remplir l'espace jusqu'à 510 octets
times padding_size db 0
; Signature de boot (2 octets)
dw 0xAA55
