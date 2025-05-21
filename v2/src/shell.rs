// src/shell.rs

use crate::keyboard;
use crate::{print, println}; // Ces macros utilisent vga_buffer en interne via main.rs
// use crate::vga_buffer; // Supprimé si non utilisé directement pour des fonctions spécifiques

const PROMPT: &str = "MONCOMBLE> ";
const MAX_COMMAND_LEN: usize = 79;

pub fn shell_run() {
    println!(); // Nouvelle ligne avant le premier prompt

    let mut command_buffer: [u8; MAX_COMMAND_LEN] = [0; MAX_COMMAND_LEN];
    // command_len sera initialisé dans la boucle

    loop {
        print!("{}", PROMPT);

        let mut command_len = 0; // Initialisation de command_len ici
        loop {
            let ch = keyboard::read_char_blocking();

            if ch == '\n' {
                println!(); // Écho de la nouvelle ligne
                break;
            } else if ch == '\x08' { // Backspace
                if command_len > 0 {
                    command_len -= 1;
                    // Effacement basique à l'écran
                    print!("\x08 \x08");
                }
            } else if ch.is_ascii_graphic() || ch == ' ' { // Caractères imprimables et espace
                if command_len < MAX_COMMAND_LEN -1 { // Laisse de la place (par ex. pour un nul si besoin)
                    command_buffer[command_len] = ch as u8;
                    command_len += 1;
                    print!("{}", ch); // Écho du caractère
                }
            }
            // Ignorer les autres caractères (contrôle, non-ascii simples, etc.)
        }

        if command_len > 0 {
            // Convertir le buffer u8 en &str pour process_command
            match core::str::from_utf8(&command_buffer[0..command_len]) {
                Ok(command_str) => process_command(command_str),
                Err(_) => println!("Erreur: Commande non UTF-8 valide."),
            }
        }
    }
}

fn process_command(command: &str) {
    if command == "help" {
        println!("Commandes disponibles:");
        println!("  help   - Affiche cette aide");
        println!("  test   - Commande de test");
        println!("  panic  - Teste le panic handler");
        // Ajoute d'autres commandes ici
    } else if command == "test" {
        println!("Ceci est une commande de test!");
    } else if command == "panic" {
        panic!("Test de panic demande par l'utilisateur!");
    } else {
        println!("Commande inconnue: '{}'", command);
    }
}
