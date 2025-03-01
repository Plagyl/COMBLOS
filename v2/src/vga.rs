/// Module d'affichage VGA en mode texte

// Constantes pour le mode texte VGA
const VGA_BUFFER: *mut u8 = 0xb8000 as *mut u8;
const VGA_WIDTH: usize = 80;
const VGA_HEIGHT: usize = 25;
const VGA_COLOR: u8 = 0x0F; // Blanc sur fond noir

// Position du curseur
static mut CURSOR_X: usize = 0;
static mut CURSOR_Y: usize = 0;

/// Efface tout l'écran (remplit de caractères espace)
pub fn clear_screen() {
    unsafe {
        for y in 0..VGA_HEIGHT {
            for x in 0..VGA_WIDTH {
                let offset = (y * VGA_WIDTH + x) * 2;
                *VGA_BUFFER.add(offset) = b' ';        // Caractère espace
                *VGA_BUFFER.add(offset + 1) = VGA_COLOR; // Attribut
            }
        }
        CURSOR_X = 0;
        CURSOR_Y = 0;
    }
}

/// Affiche un caractère à la position actuelle du curseur et avance le curseur
pub fn putchar(c: u8) {
    unsafe {
        match c {
            b'\n' => {
                // Retour à la ligne
                CURSOR_X = 0;
                CURSOR_Y += 1;
            }
            b'\r' => {
                // Retour en début de ligne
                CURSOR_X = 0;
            }
            b'\t' => {
                // Tabulation (8 espaces)
                CURSOR_X = (CURSOR_X + 8) & !7;
            }
            _ => {
                // Caractère normal
                let offset = (CURSOR_Y * VGA_WIDTH + CURSOR_X) * 2;
                *VGA_BUFFER.add(offset) = c;
                *VGA_BUFFER.add(offset + 1) = VGA_COLOR;
                
                // Avance le curseur
                CURSOR_X += 1;
            }
        }
        
        // Passage à la ligne si on atteint le bord droit
        if CURSOR_X >= VGA_WIDTH {
            CURSOR_X = 0;
            CURSOR_Y += 1;
        }
        
        // Scroll si nécessaire
        if CURSOR_Y >= VGA_HEIGHT {
            scroll();
            CURSOR_Y = VGA_HEIGHT - 1;
        }
    }
}

/// Affiche une chaîne de caractères
pub fn print(s: &str) {
    for c in s.bytes() {
        putchar(c);
    }
}

/// Affiche une chaîne de caractères suivie d'un retour à la ligne
pub fn println(s: &str) {
    print(s);
    putchar(b'\n');
}

/// Déplace tout le contenu de l'écran vers le haut d'une ligne
fn scroll() {
    unsafe {
        // Copie chaque ligne vers le haut
        for y in 1..VGA_HEIGHT {
            for x in 0..VGA_WIDTH {
                let src_offset = (y * VGA_WIDTH + x) * 2;
                let dst_offset = ((y - 1) * VGA_WIDTH + x) * 2;
                
                *VGA_BUFFER.add(dst_offset) = *VGA_BUFFER.add(src_offset);
                *VGA_BUFFER.add(dst_offset + 1) = *VGA_BUFFER.add(src_offset + 1);
            }
        }
        
        // Efface la dernière ligne
        for x in 0..VGA_WIDTH {
            let offset = ((VGA_HEIGHT - 1) * VGA_WIDTH + x) * 2;
            *VGA_BUFFER.add(offset) = b' ';
            *VGA_BUFFER.add(offset + 1) = VGA_COLOR;
        }
    }
}
