use core::panic::PanicInfo;

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    // En cas de panique, on affiche un message simple à l'écran
    let vga_buffer = 0xB8000 as *mut u8;
    let panic_msg = b"KERNEL PANIC!";
    
    unsafe {
        // Écrire le message en rouge sur noir
        for (i, &byte) in panic_msg.iter().enumerate() {
            *vga_buffer.offset(i as isize * 2) = byte;
            *vga_buffer.offset(i as isize * 2 + 1) = 0x4F; // Rouge sur noir
        }
    }
    
    // Boucle infinie
    loop {
        unsafe {
            core::arch::asm!("hlt", options(nomem, nostack));
        }
    }
}
