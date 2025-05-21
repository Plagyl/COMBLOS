// src/panic.rs
use core::panic::PanicInfo;
// Si tu veux utiliser tes macros globales ici, assure-toi qu'elles sont accessibles
// et ne causent pas de récursion ou de problèmes si la panique vient de là.
// Pour un handler de panique, il est souvent plus sûr d'utiliser des méthodes d'affichage
// très bas niveau et directes si possible, ou au moins serial_println.

// Exemple: si tu veux utiliser la macro serial_println! définie dans main.rs:
// use crate::serial_println;

#[panic_handler]
fn panic(info: &PanicInfo) -> ! {
    // Essayer d'utiliser serial_println! s'il est disponible et sûr
    // Pour cela, il faudrait que crate::serial_println! soit accessible
    // et que le port série soit dans un état utilisable.
    // Alternativement, écriture directe sur le port série ou VGA.
    // Exemple simple d'écriture directe sur VGA (attention, peut être problématique si VGA est la cause de la panique)
    let vga_buffer = 0xB8000 as *mut u8;
    let panic_msg = b"PANIC: "; // Message court
    
    for (i, &byte) in panic_msg.iter().enumerate() {
        unsafe {
            *vga_buffer.offset(i as isize * 2) = byte;
            *vga_buffer.offset(i as isize * 2 + 1) = 0x4f; // Blanc sur Rouge
        }
    }
    
    // Ici, tu pourrais essayer d'imprimer `info` si tu as un moyen sûr
    // Par exemple, si tu avais une fonction d'écriture série bas niveau :
    // unsafe { low_level_serial_print(info.to_string().as_str()); }
    // Sinon, juste le message "PANIC" est un début.

    loop {
        unsafe {
            // Utilise `att_syntax` pour être compatible avec plus d'assembleurs/contextes
            // core::arch::asm!("hlt", options(nomem, nostack)); // syntaxe intel par défaut
            core::arch::asm!("hlt", options(nomem, nostack, att_syntax));
        }
    }
}
