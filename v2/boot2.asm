; boot2.asm - Second stage du bootloader avec chargement de kernel
[org 0x8000]
bits 16

start:
    ; Afficher un message
    mov si, message
    call print
    
    ; Charger le kernel à 0x100000 (1 MB)
    mov si, loading_kernel
    call print
    
    ; Charger le kernel depuis le secteur 10
    mov ax, 0  ; Segment 0
    mov es, ax
    
    ; Utiliser une adresse temporaire pour charger le kernel
    ; Nous le déplacerons ensuite vers 0x100000
    mov bx, 0x9000  ; ES:BX = 0:0x9000
    
    ; Lire les secteurs
    mov ah, 0x02    ; Fonction BIOS pour lire les secteurs
    mov al, 64      ; Nombre de secteurs à lire (32 KB)
    mov ch, 0       ; Cylindre 0
    mov cl, 10      ; Secteur 10 (après boot1 et boot2)
    mov dh, 0       ; Tête 0
    mov dl, 0x80    ; Premier disque dur
    int 0x13
    jc error
    
    ; Maintenant nous devons copier le kernel à 0x100000
    mov si, copying_kernel
    call print
    
    ; Mettre en place la GDT
    cli
    lgdt [gdt_descriptor]
    
    ; Passer en mode protégé
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    
    ; Saut lointain pour vider le pipeline et charger CS
    jmp 0x08:protected_mode

error:
    mov si, error_msg
    call print
    cli
    hlt
    jmp $

print:
    mov ah, 0x0E
.loop:
    lodsb
    test al, al
    jz .done
    int 0x10
    jmp .loop
.done:
    ret

bits 32
protected_mode:
    ; Configurer les segments
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    
    ; Configurer la pile
    mov esp, 0x90000
    
    ; Copier le kernel de 0x9000 à 0x100000
    mov esi, 0x9000       ; Source
    mov edi, 0x100000     ; Destination
    mov ecx, 0x8000       ; Nombre d'octets à copier (32 KB)
    rep movsb
    
    ; Sauter au kernel
    jmp 0x100000

bits 16
; GDT - Table globale de descripteurs
gdt_start:
    ; Descripteur NULL (obligatoire)
    dd 0, 0
    
    ; Descripteur de segment de code
    dw 0xFFFF    ; Limite (0-15)
    dw 0x0000    ; Base (0-15)
    db 0x00      ; Base (16-23)
    db 10011010b ; Accès (présent, privilège 0, type code, exécutable, direction 0, lisible)
    db 11001111b ; Granularité (4 KiB, 32 bits) + Limite (16-19)
    db 0x00      ; Base (24-31)
    
    ; Descripteur de segment de données
    dw 0xFFFF    ; Limite (0-15)
    dw 0x0000    ; Base (0-15)
    db 0x00      ; Base (16-23)
    db 10010010b ; Accès (présent, privilège 0, type données, non exécutable, direction 0, inscriptible)
    db 11001111b ; Granularité (4 KiB, 32 bits) + Limite (16-19)
    db 0x00      ; Base (24-31)
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1  ; Taille
    dd gdt_start                ; Adresse

message db 'MONCOMBLE OS Stage 2 loaded!', 13, 10, 0
loading_kernel db 'Loading kernel...', 13, 10, 0
copying_kernel db 'Copying kernel to 0x100000...', 13, 10, 0
error_msg db 'Error loading kernel!', 13, 10, 0

; Remplissage pour avoir au moins 8 secteurs
times 4096-($-$$) db 0
