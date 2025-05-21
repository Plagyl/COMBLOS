#!/bin/bash
set -e # Quitte immédiatement si une commande échoue

echo "[+] Nettoyage..."
# Nettoie les artefacts de la compilation précédente de Cargo
cargo clean
# Supprime les anciens fichiers image/bin si tu en avais
rm -f os.img boot1.bin boot2.bin KERNEL.BIN # Ces fichiers ne seront plus générés de cette manière

echo "[+] Vérification/Installation de bootimage..."
# Vérifie si bootimage est installé, sinon l'installe
if ! cargo bootimage --version &> /dev/null; then
    echo "    bootimage non trouvé. Installation de bootimage..."
    cargo install bootimage
    if ! cargo bootimage --version &> /dev/null; then
        echo "[-] Erreur: Impossible d'installer bootimage. Veuillez vérifier votre installation de Cargo."
        exit 1
    fi
    echo "    bootimage installé avec succès."
else
    echo "    bootimage est déjà installé."
fi

echo "[+] Compilation du kernel Rust et création de l'image de boot (64 bits)..."
# La cible est définie dans .cargo/config.toml (x86_64-unknown-none)
# bootimage s'occupe de compiler le noyau et de le lier avec le bootloader spécifié dans Cargo.toml.
# Nous utilisons le mode --release pour une version optimisée.
# Si tu veux un build de débogage, enlève --release.
cargo bootimage --release
# Ou simplement `cargo bootimage` pour un build de débogage

# L'image de boot finale sera créée par bootimage.
# Le nom du fichier sera typiquement :
#   target/x86_64-unknown-none/release/bootimage-MONCOMBLE_OS.bin (pour release)
# ou
#   target/x86_64-unknown-none/debug/bootimage-MONCOMBLE_OS.bin (pour debug)
# (Remplace MONCOMBLE_OS par le nom de ton package si différent)

# Récupérer le nom du package depuis Cargo.toml pour construire le chemin
PACKAGE_NAME=$(grep '^name =' Cargo.toml | head -n 1 | sed 's/name = "\(.*\)"/\1/')
if [ -z "$PACKAGE_NAME" ]; then
    echo "[-] Erreur: Impossible de déterminer le nom du package depuis Cargo.toml"
    exit 1
fi

# Détermine le chemin de l'image en fonction du mode release ou debug
# Pour cet exemple, je vais supposer un build --release comme ci-dessus.
# Si tu enlèves --release de `cargo bootimage`, change `release` en `debug` ici.
BOOTIMAGE_PATH="target/x86_64-unknown-none/release/bootimage-${PACKAGE_NAME}.bin"

if [ -f "$BOOTIMAGE_PATH" ]; then
    echo "[+] Image de boot créée avec succès: $BOOTIMAGE_PATH"
    echo "    Taille: $(du -h "$BOOTIMAGE_PATH")"
else
    echo "[-] Erreur: L'image de boot n'a pas été créée par bootimage."
    echo "    Vérifiez la sortie de 'cargo bootimage'."
    exit 1
fi

echo "[+] Build terminé."
echo "[+] Pour lancer QEMU (exemple pour 64 bits) :"
echo "    qemu-system-x86_64 -drive format=raw,file=\"${BOOTIMAGE_PATH}\" -serial stdio"
# Tu peux ajouter d'autres options à QEMU si besoin, par exemple :
# echo "    qemu-system-x86_64 -drive format=raw,file=\"${BOOTIMAGE_PATH}\" -serial stdio -m 2G"
