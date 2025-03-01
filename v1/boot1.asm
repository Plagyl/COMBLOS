; ============================================================================
; boot1.asm – Stage1 Hybride (512 octets)
; ============================================================================
; Hypothèses :
;   - Ce code est écrit au SECTEUR 0 de la partition (VBR).
;   - Le BIOS charge ce secteur à 0x7C00 et exécute le code.
;   - Le BPB (les 90 premiers octets) est conservé via l'inclusion de bpb.bin.
;   - À partir de l'offset 90, on charge le stage2.
; ============================================================================
[org 0]
incbin "bpb.bin"      ; Inclusion des 90 premiers octets (BPB FAT32 intact)

; À partir de l'offset 90, on insère notre code de chargement
[org 90]
bits 16

start:
    cli
    mov ax, 0x07C0
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    ; Préparation du Disk Address Packet (DAP) pour lire le stage2
    ; On lit 1 secteur depuis LBA = 1 dans la RAM à 0x8000
    mov word [dap+0], 0x0010    ; packet_size = 16
    mov byte [dap+2], 0         ; reserved
    mov byte [dap+3], 1         ; num_sect = 1
    mov word [dap+4], 0x8000    ; destination offset = 0x8000
    mov word [dap+6], 0x0000    ; destination segment = 0
    xor eax, eax
    inc eax                   ; eax = 1 => LBA = 1
    mov [dap_lba], eax        ; bas 4 octets de LBA
    mov [dap_lba+4], eax      ; haut de LBA = 0
    mov dword [dap+8], eax    ; LBA = 1
    mov dword [dap+12], 0     ; LBA high = 0

    mov ax, cs
    mov es, ax
    lea si, [dap]
    mov ah, 0x42
    mov dl, 0x80             ; 1er disque dur
    int 0x13
    jc stage2_error
    jmp 0x0000:0x8000        ; Saut vers le stage2 chargé à 0x8000

stage2_error:
    cli
.error_loop:
    hlt
    jmp .error_loop

; Structure DAP (16 octets)
dap:
    db 16,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0
dap_lba:
    dd 0
    dd 0

times (510 - ($)) db 0
dw 0xAA55

