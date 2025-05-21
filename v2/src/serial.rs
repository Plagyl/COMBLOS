// src/serial.rs
use uart_16550::SerialPort;
use spin::Mutex;
use lazy_static::lazy_static;

lazy_static! {
    pub static ref SERIAL1: Mutex<SerialPort> = {
        let mut serial_port = unsafe { SerialPort::new(0x3F8) }; // Port COM1 standard
        serial_port.init();
        Mutex::new(serial_port)
    };
}

#[doc(hidden)]
pub fn _print(args: ::core::fmt::Arguments) {
    use core::fmt::Write;
    SERIAL1.lock().write_fmt(args).expect("Printing to serial failed");
}

/// Initialise le port série (appelée depuis main.rs).
/// Cette fonction est un peu redondante si lazy_static initialise déjà,
/// mais elle peut être utilisée pour forcer l'initialisation ou pour des étapes supplémentaires.
pub fn init_serial() {
    // L'initialisation est déjà faite par lazy_static, mais on peut la "toucher" pour être sûr.
    lazy_static::initialize(&SERIAL1);
    // Tu pourrais ajouter un message de confirmation ici si tu veux :
    // _print(format_args!("Serial port COM1 initialized at 0x3F8\n"));
}
