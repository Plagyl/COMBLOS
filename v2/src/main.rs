#![no_std]
#![no_main]

mod panic;
mod vga;
mod keyboard;
mod interrupts;
mod shell;
mod memory;

// Point d'entrée avec attribut section pour le linker
#[no_mangle]
#[link_section = ".text._start"]
pub extern "C" fn _start() -> ! {
    // Clear the screen first
    vga::clear_screen();
    
    // Display boot message
    vga::println("MONCOMBLE OS RUST BOOT OK!");
    
    // Initialize keyboard only - no interrupts for now
    keyboard::init();
    
    vga::println("Testing keyboard input...");
    vga::println("Press any key to continue...");
    
    // Direct keyboard debug area
    write_debug_message("Waiting for key press...");
    
    // Spin while waiting for key input
    let mut key_pressed = false;
    let mut counter = 0;
    
    while !key_pressed {
        // Test direct keyboard input
        if let Some(key) = keyboard::read_char() {
            // Print the key
            write_debug_message("Key detected!");
            vga::print("Key pressed: ");
            vga::putchar(key);
            vga::println("");
            key_pressed = true;
        }
        
        // Visual feedback to show we're running
        counter += 1;
        if counter % 100000 == 0 {
            update_progress_indicator(counter / 100000);
        }
    }
    
    vga::println("Initializing shell...");
    
    // Start the shell
    let mut shell = shell::Shell::new();
    shell.run();
    
    // This should never be reached, but just in case
    loop {
        unsafe {
            core::arch::asm!("hlt", options(nomem, nostack));
        }
    }
}

// Write debug message at the bottom of the screen
fn write_debug_message(msg: &str) {
    unsafe {
        let vga_buffer = 0xB8000 as *mut u8;
        let row = 23;
        let col = 0;
        let pos = (row * 80 + col) * 2;
        
        // Clear the line first
        for i in 0..80 {
            *vga_buffer.add(pos + i * 2) = b' ';
            *vga_buffer.add(pos + i * 2 + 1) = 0x07;
        }
        
        // Write the message
        for (i, &byte) in msg.as_bytes().iter().enumerate() {
            *vga_buffer.add(pos + i * 2) = byte;
            *vga_buffer.add(pos + i * 2 + 1) = 0x0F; // White on black
        }
    }
}

// Update progress indicator character
fn update_progress_indicator(value: usize) {
    unsafe {
        let vga_buffer = 0xB8000 as *mut u8;
        let row = 23;
        let col = 70;
        let pos = (row * 80 + col) * 2;
        
        let chars = b"-\\|/";
        let idx = value % 4;
        
        *vga_buffer.add(pos) = chars[idx];
        *vga_buffer.add(pos + 1) = 0x0E; // Yellow on black
    }
}
