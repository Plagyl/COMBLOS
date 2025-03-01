// Ultra-simplified keyboard driver specifically for QEMU
use crate::vga;

// PS/2 controller ports
const KEYBOARD_DATA_PORT: u16 = 0x60;
const KEYBOARD_STATUS_PORT: u16 = 0x64;

// Initialize keyboard (minimal setup)
pub fn init() {
    // Just display a message and clear any pending data
    vga::println("Basic keyboard driver initialized");
    
    // Read any data that might be in the buffer
    unsafe {
        // Just read a couple of times to clear any pending data
        let _ = inb(KEYBOARD_DATA_PORT);
        let _ = inb(KEYBOARD_DATA_PORT);
    }
    
    // Set up our debug display
    update_debug_area("Keyboard ready", 0);
}

// Display debug information on screen
fn update_debug_area(message: &str, value: u8) {
    // Write to the bottom line of the screen
    unsafe {
        let vga_buffer = 0xB8000 as *mut u8;
        let row = 24;
        let start_pos = row * 80 * 2;
        
        // Clear the line
        for i in 0..80 {
            *vga_buffer.add(start_pos + i * 2) = b' ';
            *vga_buffer.add(start_pos + i * 2 + 1) = 0x07;
        }
        
        // Write the message
        for (i, &byte) in message.as_bytes().iter().enumerate() {
            *vga_buffer.add(start_pos + i * 2) = byte;
            *vga_buffer.add(start_pos + i * 2 + 1) = 0x0F;
        }
        
        // Write hex value at end of message
        let pos = start_pos + message.len() * 2;
        let hex_chars = b"0123456789ABCDEF";
        *vga_buffer.add(pos) = b' ';
        *vga_buffer.add(pos + 1) = 0x0F;
        *vga_buffer.add(pos + 2) = b'0';
        *vga_buffer.add(pos + 3) = 0x0F;
        *vga_buffer.add(pos + 4) = b'x';
        *vga_buffer.add(pos + 5) = 0x0F;
        *vga_buffer.add(pos + 6) = hex_chars[(value >> 4) as usize];
        *vga_buffer.add(pos + 7) = 0x0F;
        *vga_buffer.add(pos + 8) = hex_chars[(value & 0xF) as usize];
        *vga_buffer.add(pos + 9) = 0x0F;
        
        // Add a spinner at the end of the screen
        static mut SPINNER: usize = 0;
        let spinner_chars = b"|/-\\";
        let spinner_pos = start_pos + 78 * 2;
        
        SPINNER = (SPINNER + 1) % 4;
        *vga_buffer.add(spinner_pos) = spinner_chars[SPINNER];
        *vga_buffer.add(spinner_pos + 1) = 0x0E; // Yellow on black
    }
}

// Function to handle keyboard interrupts (not used but kept for API compatibility)
pub unsafe fn handle_keyboard_interrupt() {
    let scancode = inb(KEYBOARD_DATA_PORT);
    update_debug_area("Interrupt", scancode);
}

// Non-blocking keyboard read - returns Some(key) if available, None otherwise
pub fn read_char() -> Option<u8> {
    unsafe {
        // Direct polling - check status register bit 0 (output buffer full)
        let status = inb(KEYBOARD_STATUS_PORT);
        
        // Show the status on screen
        update_debug_area("Status", status);
        
        // If bit 0 is set, there's data to read
        if status & 1 != 0 {
            let scancode = inb(KEYBOARD_DATA_PORT);
            
            // Show the scancode
            update_debug_area("Key", scancode);
            
            // Very simple mapping for common QEMU scancodes
            return match scancode {
                0x01 => Some(b'1'),  // Escape (used as 1 for testing)
                0x02 => Some(b'1'),
                0x03 => Some(b'2'),
                0x04 => Some(b'3'),
                0x05 => Some(b'4'),
                0x06 => Some(b'5'),
                0x07 => Some(b'6'),
                0x08 => Some(b'7'),
                0x09 => Some(b'8'),
                0x0A => Some(b'9'),
                0x0B => Some(b'0'),
                0x0E => Some(8),     // Backspace
                0x10 => Some(b'q'),
                0x11 => Some(b'w'),
                0x12 => Some(b'e'),
                0x13 => Some(b'r'),
                0x14 => Some(b't'),
                0x15 => Some(b'y'),
                0x16 => Some(b'u'),
                0x17 => Some(b'i'),
                0x18 => Some(b'o'),
                0x19 => Some(b'p'),
                0x1C => Some(b'\n'), // Enter
                0x1E => Some(b'a'),
                0x1F => Some(b's'),
                0x20 => Some(b'd'),
                0x21 => Some(b'f'),
                0x22 => Some(b'g'),
                0x23 => Some(b'h'),
                0x24 => Some(b'j'),
                0x25 => Some(b'k'),
                0x26 => Some(b'l'),
                0x2C => Some(b'z'),
                0x2D => Some(b'x'),
                0x2E => Some(b'c'),
                0x2F => Some(b'v'),
                0x30 => Some(b'b'),
                0x31 => Some(b'n'),
                0x32 => Some(b'm'),
                0x39 => Some(b' '), // Space
                _ => None
            };
        }
    }
    
    None
}

// Blocking keyboard read
pub fn read_char_blocking() -> u8 {
    loop {
        if let Some(ch) = read_char() {
            return ch;
        }
        
        // Small delay to avoid hammering the I/O ports too hard
        for _ in 0..1000 {
            unsafe {
                core::arch::asm!("pause", options(nomem, nostack));
            }
        }
    }
}

// Read a line of input
pub fn read_line(buffer: &mut [u8], max_len: usize) -> usize {
    let mut count = 0;
    
    while count < max_len - 1 {
        let ch = read_char_blocking();
        
        match ch {
            b'\n' => {
                buffer[count] = 0; // Null terminate
                vga::putchar(b'\n');
                return count;
            },
            8 => { // Backspace
                if count > 0 {
                    count -= 1;
                    // Update display
                    vga::putchar(8);
                    vga::putchar(b' ');
                    vga::putchar(8);
                }
            },
            _ => {
                buffer[count] = ch;
                vga::putchar(ch);
                count += 1;
            }
        }
    }
    
    buffer[count] = 0; // Null terminate
    count
}

// Low-level port I/O functions
unsafe fn inb(port: u16) -> u8 {
    let value: u8;
    core::arch::asm!("in al, dx", out("al") value, in("dx") port, options(nomem, nostack));
    value
}

unsafe fn outb(port: u16, value: u8) {
    core::arch::asm!("out dx, al", in("dx") port, in("al") value, options(nomem, nostack));
}
