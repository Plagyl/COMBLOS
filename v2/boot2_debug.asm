; =============================================================================
; boot2_debug.asm -- Version avec debug de la recherche de fichier
; =============================================================================
[org 0x8000]
bits 16

%define KERNEL_LOAD   0x100000
%define STACK_16      0x9000
%define STACK_32      0x200000

%define CODE32_SEL    0x08
%define DATA32_SEL    0x10

; Cette chaîne est la clé - assurez-vous qu'elle a 11 caractères
; Les 8 premiers sont le nom, les 3 derniers l'extension
; Les espaces sont ajoutés pour compléter le nom si nécessaire
KernelName db "KERNEL  BIN"

%define BPB_BytsPerSec 0x0B
%define BPB_SecPerClus 0x0D
%define BPB_RsvdSecCnt 0x0E
%define BPB_NumFATs    0x10
%define BPB_FATSz32    0x24
%define BPB_RootClus   0x2C

bpbBytesPerSec dw 0
bpbSecPerClus  db 0
bpbRsvdSecCnt  dw 0
bpbNumFATs     db 0
bpbFATSize     dd 0
bpbRootClus    dd 0
KernelStartClus dd 0

SectorBuf times 512 db 0
EntryBuf times 32 db 0  ; Buffer pour stocker une entrée de répertoire

GDT: times 30 db 0

_start2:
    cli
    mov ax, 0
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, STACK_16
    sti

    ; Afficher message de démarrage Stage2
    mov si, stage2_msg
    call print_string

    ; Lire la BPB depuis LBA=0 (secteur 0, partitionless)
    mov si, read_bpb_msg
    call print_string
    call read_bpb

    ; Afficher les paramètres BPB
    mov si, bpb_params_msg
    call print_string
    
    mov si, bytes_per_sec_msg
    call print_string
    movzx eax, word [bpbBytesPerSec]
    call print_dec
    mov si, newline
    call print_string
    
    mov si, sec_per_clus_msg
    call print_string
    movzx eax, byte [bpbSecPerClus]
    call print_dec
    mov si, newline
    call print_string
    
    mov si, root_clus_msg
    call print_string
    mov eax, [bpbRootClus]
    call print_hex
    mov si, newline
    call print_string

    ; Rechercher "KERNEL  BIN" dans la root directory
    mov si, find_kernel_msg
    call print_string
    call find_kernel
    cmp dword [KernelStartClus], 0
    jne .found
    mov si, kernel_not_found_msg
    call print_string
    jmp .halt

.found:
    ; Afficher le message de kernel trouvé
    mov si, kernel_found_msg
    call print_string

    ; Afficher le cluster de départ en hex
    mov eax, [KernelStartClus]
    call print_hex
    mov si, newline
    call print_string

    ; Charger KERNEL.BIN à 0x100000
    mov si, load_kernel_msg
    call print_string
    mov edx, [KernelStartClus]
    call load_file_clusters

    ; Passer en mode protégé
    mov si, entering_pm_msg
    call print_string
    
    cli
    call setup_gdt
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    jmp CODE32_SEL:pm_entry

.halt:
    mov si, halting_msg
    call print_string
    hlt
    jmp .halt

[bits 32]
pm_entry:
    mov ax, DATA32_SEL
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov esp, STACK_32
    jmp KERNEL_LOAD

[bits 16]

; --- print_string: affiche une chaîne terminée par 0
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

; --- print_hex: affiche EAX en hexadécimal
print_hex:
    pusha
    mov cx, 8       ; 8 chiffres pour 32 bits
    mov bx, hex_chars
.digit_loop:
    rol eax, 4      ; Rotation de 4 bits pour obtenir le digit de poids fort
    mov di, ax
    and di, 0x0F    ; Masque pour ne garder que les 4 bits de poids faible
    mov dl, [bx+di] ; Récupérer le caractère hex correspondant
    mov ah, 0x0E
    mov al, dl
    int 0x10
    loop .digit_loop
    popa
    ret

; --- print_dec: affiche EAX en décimal
print_dec:
    pusha
    mov ebx, 10  ; Diviseur
    mov cx, 0    ; Compteur de chiffres
    
    ; Cas spécial: 0
    test eax, eax
    jnz .divide_loop
    mov ah, 0x0E
    mov al, '0'
    int 0x10
    popa
    ret
    
.divide_loop:
    test eax, eax
    jz .print_loop
    xor edx, edx
    div ebx
    push dx     ; Empiler le reste (chiffre)
    inc cx
    jmp .divide_loop
    
.print_loop:
    test cx, cx
    jz .done
    pop ax      ; Dépiler un chiffre
    add al, '0' ; Convertir en ASCII
    mov ah, 0x0E
    int 0x10
    dec cx
    jmp .print_loop
    
.done:
    popa
    ret

; --- print_entry: affiche une entrée de répertoire (pour debug)
print_entry:
    pusha
    mov cx, 11  ; Taille du nom de fichier 8.3
    mov si, EntryBuf
.print_loop:
    lodsb
    mov ah, 0x0E
    int 0x10
    loop .print_loop
    popa
    ret

; --- read_bpb : lit LBA=0 => SectorBuf, extrait la BPB
read_bpb:
    pusha
    xor eax,eax
    call bios_read_one_sector
    jc .error
    mov ax, [SectorBuf + BPB_BytsPerSec]
    mov [bpbBytesPerSec], ax
    mov al, [SectorBuf + BPB_SecPerClus]
    mov [bpbSecPerClus], al
    mov ax, [SectorBuf + BPB_RsvdSecCnt]
    mov [bpbRsvdSecCnt], ax
    mov al, [SectorBuf + BPB_NumFATs]
    mov [bpbNumFATs], al
    mov eax, [SectorBuf + BPB_FATSz32]
    mov [bpbFATSize], eax
    mov eax, [SectorBuf + BPB_RootClus]
    mov [bpbRootClus], eax
    
    ; Afficher les informations BPB
    mov si, bpb_info_msg
    call print_string
    popa
    ret
.error:
    mov si, read_bpb_error_msg
    call print_string
    popa
    jmp halt_cpu

; --- find_kernel : recherche "KERNEL  BIN"
find_kernel:
    pusha
    mov edx, [bpbRootClus]
    mov si, root_dir_msg
    call print_string
    mov eax, edx
    call print_hex
    mov si, newline
    call print_string

.searchRoot:
    cmp edx, 0x0FFFFFF8
    jae .notFound
    
    ; Afficher le cluster en cours d'analyse
    mov si, checking_cluster_msg
    call print_string
    mov eax, edx
    call print_hex
    mov si, newline
    call print_string
    
    call read_cluster
    jc .error
    
    mov ax, [bpbBytesPerSec]
    movzx ecx, byte [bpbSecPerClus]
    mul ecx         ; AX = taille du cluster en octets
    mov cx, 32      ; Taille d'une entrée de répertoire
    div cx          ; AX = nombre d'entrées par cluster
    
    ; Afficher combien d'entrées on va analyser
    mov si, checking_entries_msg
    call print_string
    movzx eax, ax
    call print_dec
    mov si, newline
    call print_string
    
    mov si, SectorBuf
    
.entryLoop:
    cmp ax, 0
    je .nextCluster
    
    ; Si premier octet = 0, fin du répertoire
    cmp byte [si], 0
    je .notFound
    
    ; Si premier octet = 0xE5, entrée supprimée
    cmp byte [si], 0xE5
    je .skip
    
    ; Afficher le nom du fichier analysé
    mov di, si
    mov cx, 11
    mov bx, EntryBuf
.copy_name:
    mov al, [di]
    mov [bx], al
    inc di
    inc bx
    loop .copy_name
    
    mov si, checking_file_msg
    call print_string
    call print_entry
    mov si, newline
    call print_string
    
    ; Restaurer SI qui a été avancé par print_string
    sub si, 11 
    add si, 32  ; On recule de 11 puis on avance de 32 pour revenir à l'entrée courante
    
    ; Vérifier si c'est un répertoire (attribut = 0x10)
    test byte [si+11], 0x10
    jnz .skip   ; Si c'est un répertoire, on passe
    
    ; Comparer avec KernelName
    push ax
    push si
    mov di, KernelName
    mov cx, 11
    mov si, EntryBuf
    call compare_str
    pop si
    pop ax
    
    cmp cx, 0
    jne .skip
    
    ; Trouvé ! Récupérer le cluster de départ
    movzx eax, word [si+0x14]  ; Bits de poids fort
    movzx edx, word [si+0x1A]  ; Bits de poids faible
    shl eax, 16
    or eax, edx
    mov [KernelStartClus], eax
    
    ; Afficher le nom du fichier trouvé
    mov si, file_found_msg
    call print_string
    call print_entry
    mov si, newline
    call print_string
    
    jmp .done
    
.skip:
    add si, 32      ; Passer à l'entrée suivante
    dec ax
    jmp .entryLoop

.nextCluster:
    ; Afficher qu'on passe au cluster suivant
    mov si, next_cluster_msg
    call print_string
    
    call next_cluster_in_fat
    mov edx, eax
    
    ; Afficher le cluster suivant
    call print_hex
    mov si, newline
    call print_string
    
    jmp .searchRoot
    
.notFound:
    mov si, no_files_msg
    call print_string
    mov dword [KernelStartClus], 0
    
.done:
    popa
    ret
    
.error:
    mov si, find_kernel_error_msg
    call print_string
    popa
    jmp halt_cpu

; --- load_file_clusters : charge KERNEL.BIN à KERNEL_LOAD
load_file_clusters:
    pusha
    mov edi, KERNEL_LOAD
.loadLoop:
    cmp edx, 0x0FFFFFF8
    jae .done
    call read_cluster
    jc .error
    mov ax, [bpbBytesPerSec]
    movzx ecx, byte [bpbSecPerClus]
    mul ecx
    mov cx, ax
    mov esi, SectorBuf
    rep movsb
    call next_cluster_in_fat
    mov edx, eax
    jmp .loadLoop
.done:
    ; Afficher un message de chargement réussi
    mov si, kernel_loaded_msg
    call print_string
    popa
    ret
.error:
    mov si, load_kernel_error_msg
    call print_string
    popa
    jmp halt_cpu

; --- read_cluster : calcule LBA, lit [bpbSecPerClus] secteurs => SectorBuf
read_cluster:
    pusha
    mov ax, [bpbRsvdSecCnt]
    movzx eax, ax
    movzx ecx, byte [bpbNumFATs]
    mov ebx, [bpbFATSize]
    imul ecx, ebx
    add eax, ecx
    mov ecx, edx
    sub ecx, 2
    movzx ebx, byte [bpbSecPerClus]
    imul ecx, ebx
    add eax, ecx
    movzx ecx, byte [bpbSecPerClus]
    mov edi, SectorBuf
.read_sector_loop:
    push eax
    call bios_read_one_sector
    jc .error
    pop eax
    add edi, 512
    inc eax
    loop .read_sector_loop
    clc  ; Clear carry flag (success)
    popa
    ret
.error:
    mov si, read_cluster_error_msg
    call print_string
    stc  ; Set carry flag (error)
    popa
    ret

; --- next_cluster_in_fat : EDX=cluster => EAX=cluster_suivant
next_cluster_in_fat:
    pusha
    mov eax, edx
    mov ebx, 4
    imul eax, ebx
    mov esi, eax
    mov ax, [bpbBytesPerSec]
    movzx ebx, ax
    mov eax, esi
    xor edx, edx
    div ebx
    movzx ecx, word [bpbRsvdSecCnt]
    add ecx, eax
    mov eax, ecx
    call bios_read_one_sector2
    jc .error
    mov eax, dword [SectorBuf2 + edx]
    and eax, 0x0FFFFFFF
    popa
    ret
.error:
    mov si, fat_error_msg
    call print_string
    popa
    xor eax, eax  ; Return 0 on error
    ret

; --- compare_str
compare_str:
    push ax
.cmp_loop:
    cmp cx, 0
    je .cmp_done
    lodsb
    scasb
    jne .cmp_diff
    loop .cmp_loop
.cmp_done:
    pop ax
    ret
.cmp_diff:
    mov cx,1
    pop ax
    ret

; --- bios_read_one_sector
bios_read_one_sector:
    pusha
    mov byte [dap_size], 16
    mov byte [dap+1], 0
    mov word [dap+2], 1
    mov word [dap+4], SectorBuf
    mov word [dap+6], ds
    mov dword [dap+8], eax
    mov dword [dap+12], 0
    mov ah, 0x42
    mov dl, 0x80
    lea si,[dap]
    int 0x13
    jc .error
    popa
    clc  ; Clear carry flag (success)
    ret
.error:
    popa
    stc  ; Set carry flag (error)
    ret

; --- bios_read_one_sector2
bios_read_one_sector2:
    pusha
    mov byte [dap_size], 16
    mov byte [dap+1], 0
    mov word [dap+2], 1
    mov word [dap+4], SectorBuf2
    mov word [dap+6], ds
    mov dword [dap+8], eax
    mov dword [dap+12], 0
    mov ah, 0x42
    mov dl, 0x80
    lea si,[dap]
    int 0x13
    jc .error
    popa
    clc  ; Clear carry flag (success)
    ret
.error:
    popa
    stc  ; Set carry flag (error)
    ret

setup_gdt:
    xor eax,eax
    inc eax
    mov bx, GDT
    ; Null descriptor
    mov dword [bx+0], 0
    mov dword [bx+4], 0

    ; Code segment: base=0, limit=0xFFFFF (4K gran), type=0x9A
    mov word [bx+8], 0xFFFF
    mov word [bx+10], 0x0000
    mov byte [bx+12], 0x00
    mov byte [bx+13], 0x9A
    mov byte [bx+14], 0xCF
    mov byte [bx+15], 0x00

    ; Data segment: base=0, limit=0xFFFFF (4K gran), type=0x92
    mov word [bx+16], 0xFFFF
    mov word [bx+18], 0x0000
    mov byte [bx+20], 0x00
    mov byte [bx+21], 0x92
    mov byte [bx+22], 0xCF
    mov byte [bx+23], 0x00

    ; GDTR
    mov word [bx+24], 24-1
    mov word [bx+26], bx
    mov dword [bx+28], 0
    lgdt [bx+24]
    ret

; Fonction pour arrêter le CPU en cas d'erreur
halt_cpu:
    mov si, fatal_error_msg
    call print_string
    cli
    hlt
    jmp halt_cpu

; Messages
stage2_msg          db "MONCOMBLE_OS Stage 2 starting...", 13, 10, 0
read_bpb_msg        db "Reading BPB...", 13, 10, 0
bpb_info_msg        db "BPB read successfully", 13, 10, 0
bpb_params_msg      db "BPB Parameters:", 13, 10, 0
bytes_per_sec_msg   db "  Bytes per sector: ", 0
sec_per_clus_msg    db "  Sectors per cluster: ", 0
root_clus_msg       db "  Root directory cluster: 0x", 0
find_kernel_msg     db "Searching for KERNEL.BIN...", 13, 10, 0
root_dir_msg        db "Root directory is at cluster 0x", 0
checking_cluster_msg db "Checking cluster 0x", 0
checking_entries_msg db "Checking entries: ", 0
checking_file_msg   db "Found file: ", 0
file_found_msg      db "Match found: ", 0
next_cluster_msg    db "Moving to next cluster: 0x", 0
no_files_msg        db "No more files in directory", 13, 10, 0
kernel_found_msg    db "KERNEL.BIN found! Starting cluster: 0x", 0
kernel_not_found_msg db "KERNEL.BIN not found!", 13, 10, 0
load_kernel_msg     db "Loading KERNEL.BIN at 0x100000...", 13, 10, 0
kernel_loaded_msg   db "Kernel loaded successfully", 13, 10, 0
entering_pm_msg     db "Entering protected mode...", 13, 10, 0
halting_msg         db "System halted.", 13, 10, 0
newline             db 13, 10, 0
read_bpb_error_msg  db "Error reading BPB!", 13, 10, 0
find_kernel_error_msg db "Error searching for kernel!", 13, 10, 0
load_kernel_error_msg db "Error loading kernel!", 13, 10, 0
read_cluster_error_msg db "Error reading cluster!", 13, 10, 0
fat_error_msg       db "Error reading FAT!", 13, 10, 0
fatal_error_msg     db "FATAL ERROR! System halted.", 13, 10, 0

; Caractères hexadécimaux
hex_chars           db "0123456789ABCDEF"

SectorBuf2 times 512 db 0
dap_size db 0
dap: times 16 db 0

times 4096 - ($ - $$) db 0
