use core::arch::asm;

// PIC constants
const PIC1_COMMAND: u16 = 0x20;
const PIC1_DATA: u16 = 0x21;
const PIC2_COMMAND: u16 = 0xA0;
const PIC2_DATA: u16 = 0xA1;

// Initialization Command Words
const ICW1_INIT: u8 = 0x11;
const ICW4_8086: u8 = 0x01;

// IDT entry structure
#[repr(C, packed)]
#[derive(Copy, Clone)]
struct IdtEntry {
    offset_low: u16,
    selector: u16,
    zero: u8,
    type_attr: u8,
    offset_high: u16,
}

// IDTR structure for loading the IDT
#[repr(C, packed)]
struct Idtr {
    limit: u16,
    base: u32,
}

// IDT with 256 entries
static mut IDT: [IdtEntry; 256] = [IdtEntry {
    offset_low: 0,
    selector: 0,
    zero: 0,
    type_attr: 0,
    offset_high: 0,
}; 256];

static mut IDTR: Idtr = Idtr { limit: 0, base: 0 };

// Initialize interrupt handling
pub fn init() {
    unsafe {
        // Initialize PIC
        init_pic();
        
        // Set up the IDT
        for i in 0..256 {
            set_idt_entry(i, default_handler as usize, 0x08, 0x8E);
        }
        
        // Set up keyboard handler
        set_idt_entry(0x21, keyboard_handler as usize, 0x08, 0x8E);
        
        // Set up the IDTR
        IDTR.limit = (core::mem::size_of::<[IdtEntry; 256]>() - 1) as u16;
        IDTR.base = IDT.as_ptr() as u32;
        
        // Load the IDT
        asm!("lidt [{}]", in(reg) &IDTR, options(nostack));
        
        // Start with all interrupts masked except for the keyboard
        outb(PIC1_DATA, 0xFD); // 1111 1101 - unmask IRQ1 (keyboard)
        outb(PIC2_DATA, 0xFF); // mask all IRQs on PIC2
        
        // Small delay to ensure PIC is ready
        for _ in 0..1000 {
            core::hint::spin_loop();
        }
        
        // Enable interrupts
        asm!("sti", options(nomem, nostack));
    }
}

// Initialize the Programmable Interrupt Controller with careful timing
unsafe fn init_pic() {
    // ICW1: start initialization sequence
    outb(PIC1_COMMAND, ICW1_INIT);
    io_wait();
    outb(PIC2_COMMAND, ICW1_INIT);
    io_wait();
    
    // ICW2: define PIC vectors
    outb(PIC1_DATA, 0x20); // IRQ 0-7 maps to 0x20-0x27
    io_wait();
    outb(PIC2_DATA, 0x28); // IRQ 8-15 maps to 0x28-0x2F
    io_wait();
    
    // ICW3: tell PICs about each other
    outb(PIC1_DATA, 4);    // PIC1 has PIC2 at IRQ2 (0000 0100)
    io_wait();
    outb(PIC2_DATA, 2);    // PIC2 has cascade identity 2
    io_wait();
    
    // ICW4: additional information
    outb(PIC1_DATA, ICW4_8086);
    io_wait();
    outb(PIC2_DATA, ICW4_8086);
    io_wait();
    
    // Mask all interrupts initially
    outb(PIC1_DATA, 0xFF);
    io_wait();
    outb(PIC2_DATA, 0xFF);
    io_wait();
}

// A delay for PIC initialization
unsafe fn io_wait() {
    // Simple I/O delay by reading from an unused port
    outb(0x80, 0);
}

// Set an entry in the IDT
unsafe fn set_idt_entry(index: usize, handler: usize, selector: u16, type_attr: u8) {
    IDT[index].offset_low = (handler & 0xFFFF) as u16;
    IDT[index].selector = selector;
    IDT[index].zero = 0;
    IDT[index].type_attr = type_attr;
    IDT[index].offset_high = ((handler >> 16) & 0xFFFF) as u16;
}

// Low-level I/O port functions
pub unsafe fn outb(port: u16, value: u8) {
    asm!("out dx, al", in("dx") port, in("al") value, options(nomem, nostack));
}

pub unsafe fn inb(port: u16) -> u8 {
    let value: u8;
    asm!("in al, dx", out("al") value, in("dx") port, options(nomem, nostack));
    value
}

// Default interrupt handler
extern "C" fn default_handler() {
    unsafe {
        // Send End-of-Interrupt signal
        outb(PIC1_COMMAND, 0x20);
    }
}

// Keyboard interrupt handler
extern "C" fn keyboard_handler() {
    unsafe {
        // Read the scan code to acknowledge the interrupt
        let _scancode = inb(0x60);
        
        // We'll just handle it in a simple way for now to avoid issues
        // and just acknowledge the interrupt
        
        // Send End-of-Interrupt signal
        outb(PIC1_COMMAND, 0x20);
    }
}
