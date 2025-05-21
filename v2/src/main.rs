// src/main.rs

#![no_std]
#![no_main]
#![feature(custom_test_frameworks)]
#![feature(abi_x86_interrupt)]

extern crate alloc;

// use core::panic::PanicInfo; // Supprimé, car panic_handler est dans panic.rs
use spin::Mutex;

// --- Déclaration de tes modules ---
pub mod gdt;
pub mod interrupts;
pub mod keyboard;
pub mod memory;
pub mod panic; // Ajouté pour s'assurer que panic.rs est inclus
pub mod serial;
pub mod shell;
pub mod vga_buffer;

// ... (le reste de main.rs comme dans la réponse précédente où il compilait avec des warnings)
//       Assure-toi que les macros print/println/serial_print/serial_println sont là,
//       l'allocateur global, kernel_main, hlt_loop, et la partie test.
//       JE NE RÉPÈTE PAS TOUT POUR LA CONCISION.
//       La seule différence est la suppression de l'import PanicInfo et l'ajout de `pub mod panic;`.

// COPIE LE RESTE DE main.rs DE LA RÉPONSE PRÉCEDENTE où il compilait avec des warnings,
// ET APPLIQUE JUSTE LES DEUX CHANGEMENTS CI-DESSUS (suppression de `use ... PanicInfo` et ajout de `pub mod panic;`).

// Pour être explicite, voici la section des `pub mod` corrigée :
// pub mod gdt;
// pub mod interrupts;
// pub mod keyboard;
// pub mod memory;
// pub mod panic; // <= LIGNE AJOUTÉE
// pub mod serial;
// pub mod shell;
// pub mod vga_buffer;

// Le reste du fichier (allocateur, macros, kernel_main, hlt_loop, tests)
// reste identique à la version précédente qui compilait avec des warnings.
// (Celle que tu as utilisée pour obtenir la sortie avec l'erreur `#[panic_handler]` function required)

// --- Définition de l'allocateur global ---
#[global_allocator]
static ALLOCATOR: LockedSlabAllocator =
    LockedSlabAllocator(Mutex::new(memory::slab_allocator::SlabAllocator::new()));

pub struct LockedSlabAllocator(Mutex<memory::slab_allocator::SlabAllocator>);

unsafe impl core::alloc::GlobalAlloc for LockedSlabAllocator {
    unsafe fn alloc(&self, layout: core::alloc::Layout) -> *mut u8 {
        let mut allocator = self.0.lock();
        match allocator.allocate(layout.size()) {
            Some(ptr) => ptr,
            None => {
                // Temporairement, on ne logue rien ici pour éviter des dépendances
                // si le serial_println n'est pas encore 100% fonctionnel dans tous les contextes.
                core::ptr::null_mut()
            }
        }
    }

    unsafe fn dealloc(&self, ptr: *mut u8, _layout: core::alloc::Layout) {
        let mut allocator = self.0.lock();
        allocator.deallocate(ptr);
    }
}

// --- Macros pour l'affichage ---
#[macro_export]
macro_rules! print {
    ($($arg:tt)*) => ($crate::vga_buffer::_print(format_args!($($arg)*)));
}

#[macro_export]
macro_rules! println {
    () => ($crate::print!("\n"));
    ($($arg:tt)*) => ($crate::print!("{}\n", format_args!($($arg)*)));
}

#[macro_export]
macro_rules! serial_print {
    ($($arg:tt)*) => {
        $crate::serial::_print(format_args!($($arg)*));
    };
}

#[macro_export]
macro_rules! serial_println {
    () => ($crate::serial_print!("\n"));
    ($fmt:expr) => ($crate::serial_print!(concat!($fmt, "\n")));
    ($fmt:expr, $($arg:tt)*) => ($crate::serial_print!(
        concat!($fmt, "\n"), $($arg)*));
}

// --- Point d'entrée du noyau ---
#[no_mangle]
pub extern "C" fn kernel_main() -> ! {
    serial::init_serial();
    serial_println!("Port serie initialise.");

    gdt::init();
    serial_println!("GDT initialise.");

    interrupts::init_idt();
    // Assurez-vous que les PICs sont initialisés, soit dans init_idt, soit ici :
    // unsafe { interrupts::PICS.lock().initialize(); }
    serial_println!("IDT initialisee.");

    keyboard::init_keyboard();
    serial_println!("File d'attente clavier initialisee.");

    const HEAP_START_ADDRESS: usize = 0x400000;
    const HEAP_SIZE_BYTES: usize    = 256 * 1024;

    unsafe {
        ALLOCATOR.0.lock().init(HEAP_START_ADDRESS, HEAP_SIZE_BYTES);
    }
    serial_println!(
        "Allocateur Slab initialise. Heap de {} KiB a partir de {:#x}",
        HEAP_SIZE_BYTES / 1024,
        HEAP_START_ADDRESS
    );

    use alloc::boxed::Box;
    use alloc::vec::Vec;

    serial_println!("Test d'allocation Box::new(42)...");
    let heap_value = Box::new(42);
    serial_println!("  heap_value at {:p} -> {}", heap_value, *heap_value);
    drop(heap_value);
    serial_println!("  Box::new(42) alloue et dealloue.");

    serial_println!("Test d'allocation d'un vecteur...");
    let mut vec_test = Vec::new();
    for i in 0..5 {
        vec_test.push(i);
    }
    serial_println!("  Vecteur: {:?}", vec_test);
    serial_println!("Tests d'allocateur termines.");

    x86_64::instructions::interrupts::enable();
    serial_println!("Interruptions activees.");

    println!("Bienvenue dans MONCOMBLE OS - v2!");
    println!("Tapez 'help' pour les commandes.");

    shell::shell_run();

    hlt_loop();
}

pub fn hlt_loop() -> ! {
    loop {
        x86_64::instructions::hlt();
    }
}

// --- Configuration pour les tests ---
#[cfg(test)]
#[no_mangle]
pub extern "C" fn _start() -> ! {
    kernel_main();
    hlt_loop();
}

#[cfg(test)]
fn test_main() { /* ... */ }

#[cfg(test)]
pub fn test_runner(tests: &[&dyn Fn()]) {
    serial_println!("Running {} tests", tests.len());
    for test in tests {
        test();
    }
    exit_qemu(QemuExitCode::Success);
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[repr(u32)]
pub enum QemuExitCode {
    Success = 0x10,
    Failed = 0x11,
}

pub fn exit_qemu(exit_code: QemuExitCode) {
    use x86_64::instructions::port::Port;
    unsafe {
        let mut port = Port::new(0xf4);
        port.write(exit_code as u32);
    }
}
