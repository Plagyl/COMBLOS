use crate::vga;
use crate::keyboard;

const MAX_COMMAND_LENGTH: usize = 64;

pub struct Shell {
    prompt: &'static str,
    command_buffer: [u8; MAX_COMMAND_LENGTH],
}

impl Shell {
    pub fn new() -> Self {
        Shell {
            prompt: "MONCOMBLE> ",
            command_buffer: [0; MAX_COMMAND_LENGTH],
        }
    }

    pub fn run(&mut self) {
        // Display welcome message
        vga::println("MONCOMBLE OS Shell v0.1");
        vga::println("Type 'help' for available commands");
        vga::println("");
        
        // Main command loop
        loop {
            // Display prompt
            vga::print(self.prompt);
            
            // Wait a moment to ensure the prompt is visible
            self.short_delay();
            
            // Read command
            let len = self.read_command();
            
            if len > 0 {
                // Process command (simple version to start)
                self.process_command(len);
            }
        }
    }
    
    fn short_delay(&self) {
        // Simple delay to ensure display updates in QEMU
        for _ in 0..100000 {
            unsafe {
                core::arch::asm!("pause", options(nomem, nostack));
            }
        }
    }
    
    fn read_command(&mut self) -> usize {
        // Read input until newline
        let mut count = 0;
        
        while count < MAX_COMMAND_LENGTH - 1 {
            let ch = keyboard::read_char_blocking();
            
            match ch {
                b'\n' => {
                    self.command_buffer[count] = 0; // Null terminate
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
                    self.command_buffer[count] = ch;
                    vga::putchar(ch);
                    count += 1;
                }
            }
        }
        
        self.command_buffer[count] = 0; // Null terminate
        vga::putchar(b'\n');
        count
    }
    
    fn process_command(&self, len: usize) {
        // Convert command to string slice for easy comparison
        if let Ok(cmd) = core::str::from_utf8(&self.command_buffer[0..len]) {
            match cmd {
                "help" => {
                    vga::println("Available commands:");
                    vga::println("  help  - Display this help message");
                    vga::println("  clear - Clear the screen");
                    vga::println("  about - Display information about the OS");
                    vga::println("  echo  - Echo text back to the screen");
                },
                "clear" => {
                    vga::clear_screen();
                },
                "about" => {
                    vga::println("MONCOMBLE OS v0.1");
                    vga::println("A simple operating system written in Rust");
                    vga::println("Built with custom bootloader and kernel");
                },
                "echo" => {
                    // Simply echo back the command for now
                    vga::println(cmd);
                },
                "" => {
                    // Empty command, do nothing
                },
                _ => {
                    vga::print("Unknown command: ");
                    vga::println(cmd);
                }
            }
        } else {
            vga::println("Invalid command (non-UTF8)");
        }
    }
}
