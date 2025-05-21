// src/keyboard.rs

use conquer_once::spin::OnceCell;
use crossbeam_queue::ArrayQueue;
use crate::serial_println; // Garder pour le débogage de la queue

use lazy_static::lazy_static;
// Correction: on a besoin de ScancodeSet1 en tant que type, et d'une instance pour new()
use pc_keyboard::{layouts, DecodedKey, HandleControl, Keyboard, ScancodeSet1};
use spin::Mutex;

static SCANCODE_QUEUE: OnceCell<ArrayQueue<u8>> = OnceCell::uninit();

lazy_static! {
    static ref KEYBOARD: Mutex<Keyboard<layouts::Us104Key, ScancodeSet1>> =
        Mutex::new(Keyboard::new(
            ScancodeSet1::new(),      // <--- CORRECTION: Instance de ScancodeSet1
            layouts::Us104Key,        // <--- CORRECTION: Layout en deuxième
            HandleControl::Ignore
        ));
}

pub fn init_keyboard() {
    SCANCODE_QUEUE.init_once(|| ArrayQueue::new(100));
    serial_println!("Keyboard scancode queue initialized.");
}

pub fn add_scancode(scancode: u8) {
    if let Some(queue) = SCANCODE_QUEUE.get() {
        if queue.push(scancode).is_err() {
            serial_println!("[KEYBOARD] WARN: Scancode queue full! Scancode {:#02x} dropped.", scancode);
        }
    } else {
        serial_println!("[KEYBOARD] FATAL: Scancode queue not initialized when trying to add scancode!");
    }
}

fn read_scancode() -> Option<u8> {
    if let Some(queue) = SCANCODE_QUEUE.get() {
        queue.pop()
    } else {
        None
    }
}

pub fn read_char_blocking() -> char {
    loop {
        if let Some(scancode) = read_scancode() {
            let mut keyboard_decoder = KEYBOARD.lock();
            if let Ok(Some(key_event)) = keyboard_decoder.add_byte(scancode) {
                if let Some(decoded_key) = keyboard_decoder.process_keyevent(key_event) {
                    match decoded_key {
                        DecodedKey::Unicode(character) => return character,
                        DecodedKey::RawKey(key) => {
                            if key == pc_keyboard::KeyCode::Backspace {
                                return '\x08';
                            }
                        }
                    }
                }
            }
        } else {
            core::hint::spin_loop();
        }
    }
}
