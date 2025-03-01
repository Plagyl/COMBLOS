; ============================================================================
; stage2.asm – Stage2 Bootloader (512 octets)
; ============================================================================
; Hypothèses :
;   - Ce code est chargé en RAM à 0x8000 par stage1.
;   - Il charge KERNEL.BIN depuis le disque, à partir de LBA = 9, dans la RAM à 0x9000.
;   - Le noyau a été lié pour s’exécuter à 0x9000.
; ============================================================================
[org 0x8000]
bits 16

start_stage2:
    cli
    mov ax, 0x07C0
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    ; Préparation du DAP pour charger KERNEL.BIN
    ; On charge 32 secteurs depuis LBA = 9 dans la RAM à 0x9000
    mov word [dap2+0], 0x0010   ; packet size = 16
    mov byte [dap2+2], 0        ; reserved
    mov byte [dap2+3], 32       ; num_sect = 32 (32 x 512 = 16 KB, ajustez selon la taille du kernel)
    mov word [dap2+4], 0x9000   ; destination offset = 0x9000
    mov word [dap2+6], 0x0000   ; destination segment = 0
    mov eax, 9
    mov [dap2_lba], eax
    mov dword [dap2+8], eax     ; LBA = 9
    mov dword [dap2+12], 0
    mov ax, cs
    mov es, ax
    lea si, [dap2]
    mov ah, 0x42
    mov dl, 0x80              ; 1er disque dur
    int 0x13
    jc load_error

    ; Saut vers le kernel chargé à 0x9000
    jmp 0x0000:0x9000

load_error:
    cli
.error_loop:
    hlt
    jmp .error_loop

; Structure DAP (16 octets)
dap2:
    db 16,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0
dap2_lba:
    dd 0
    dd 0

times (510 - ($)) db 0
dw 0xAA55

