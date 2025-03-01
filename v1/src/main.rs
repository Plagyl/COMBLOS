#![no_std]
#![no_main]

mod panic;
mod memory;

use memory::slab_allocator::SlabAllocator;
use core::arch::global_asm;
use core::panic::PanicInfo;

global_asm!(
    r#"
    .section .text
    .globl _start
"#
);

static mut SLAB_ALLOCATOR: SlabAllocator = SlabAllocator::new();

#[no_mangle]
pub extern "C" fn _start() -> ! {
    // Initialisation de l’allocateur
    const HEAP_START: usize = 0xA000; // Zone de heap placée après le kernel (kernel à 0x9000)
    const HEAP_SIZE: usize = 64 * 1024; // 64 Ko de heap

    unsafe {
        SLAB_ALLOCATOR.init(HEAP_START, HEAP_SIZE);
    }

    // Test d'allocation
    let ptr1 = unsafe { SLAB_ALLOCATOR.allocate(32) };
    let ptr2 = unsafe { SLAB_ALLOCATOR.allocate(64) };

    if let Some(addr) = ptr1 {
        let slice = unsafe { core::slice::from_raw_parts_mut(addr as *mut u8, 32) };
        slice[0] = 0xAB;
        slice[1] = 0xCD;
    }

    if let Some(_addr) = ptr1 {
        unsafe { SLAB_ALLOCATOR.deallocate(ptr1.unwrap()) };
    }
    if let Some(_addr) = ptr2 {
        unsafe { SLAB_ALLOCATOR.deallocate(ptr2.unwrap()) };
    }

    // Affichage en VGA (mode texte)
    let vga_buffer = 0xb8000 as *mut u8;
    let text = b"MONCOMBLE_OS BOOT OK";
    let color = 0x0F; // Blanc sur fond noir
    for (i, &byte) in text.iter().enumerate() {
        unsafe {
            *vga_buffer.offset((i * 2) as isize) = byte;
            *vga_buffer.offset((i * 2 + 1) as isize) = color;
        }
    }

    loop {}
}

