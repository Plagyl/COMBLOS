#![no_std]
#![no_main]

mod panic;

// Point d'entrée avec attribut section pour le linker
#[no_mangle]
#[link_section = ".text._start"]
pub extern "C" fn _start() -> ! {
    // Afficher un message sur l'écran VGA
    let vga_buffer = 0xB8000 as *mut u8;
    let message = b"MONCOMBLE OS RUST BOOT OK!";
    
    for (i, &byte) in message.iter().enumerate() {
        unsafe {
            *vga_buffer.offset(i as isize * 2) = byte;
            *vga_buffer.offset(i as isize * 2 + 1) = 0x0F; // blanc sur noir
        }
    }
    
    // Boucle infinie
    loop {
        unsafe {
            core::arch::asm!("hlt", options(nomem, nostack));
        }
    }
}
