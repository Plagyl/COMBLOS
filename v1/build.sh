#!/bin/bash
set -e

# Répertoire du projet
PROJECT_DIR=$(pwd)
BUILD_DIR="$PROJECT_DIR/target/i686-none/release"
KERNEL_BIN="$BUILD_DIR/MONCOMBLE_OS"
DISK_IMG="$PROJECT_DIR/disk.img"
DISK_SIZE=64M
LOOP_DEV="/dev/loop0"
MOUNT_DIR="$PROJECT_DIR/mnt"

echo "==> Compilation du noyau Rust..."
cargo rustc -Z build-std=core,compiler_builtins --target i686-none.json --release -- -C link-arg=-Tlinker.ld -C link-arg=-nostdlib

# Le binaire est déjà nommé MONCOMBLE_OS ; on le copie sous le nom KERNEL.BIN à la racine
cp "$KERNEL_BIN" "$PROJECT_DIR/KERNEL.BIN"

echo "==> Assemblage du boot sector (stage1)..."
nasm -f bin boot1.asm -o boot1.bin
if [ $(stat -c%s "boot1.bin") -ne 512 ]; then
    echo "Erreur : boot1.bin doit faire 512 octets."
    exit 1
fi

echo "==> Assemblage du stage2..."
nasm -f bin stage2.asm -o stage2.bin
if [ $(stat -c%s "stage2.bin") -ne 512 ]; then
    echo "Erreur : stage2.bin doit faire 512 octets."
    exit 1
fi

echo "==> Création d'une image disque de $DISK_SIZE..."
dd if=/dev/zero of="$DISK_IMG" bs=1M count=64

echo "==> Partitionnement de l'image disque..."
# Créer une seule partition primaire de type FAT32
echo ",,c" | sfdisk "$DISK_IMG"

echo "==> Association de l'image au loop device..."
sudo losetup -P $LOOP_DEV "$DISK_IMG"

echo "==> Formatage de la partition en FAT32..."
sudo mkfs.fat -F 32 "${LOOP_DEV}p1"

echo "==> Extraction du BPB (90 octets) depuis la partition..."
mkdir -p "$MOUNT_DIR"
sudo mount "${LOOP_DEV}p1" "$MOUNT_DIR"
dd if="${LOOP_DEV}p1" bs=1 count=90 of=bpb.bin
sudo umount "$MOUNT_DIR"

echo "==> Copie de KERNEL.BIN dans la partition FAT32..."
sudo mount "${LOOP_DEV}p1" "$MOUNT_DIR"
sudo cp "$PROJECT_DIR/KERNEL.BIN" "$MOUNT_DIR/"
sudo sync
sudo umount "$MOUNT_DIR"

echo "==> Écriture du boot sector (stage1) dans le secteur 0 de la partition..."
sudo dd if=boot1.bin of="${LOOP_DEV}p1" bs=512 count=1 conv=notrunc

echo "==> Écriture du stage2 dans le secteur 1 de la partition..."
sudo dd if=stage2.bin of="${LOOP_DEV}p1" bs=512 count=1 seek=1 conv=notrunc

echo "==> Détachement du loop device..."
sudo losetup -d $LOOP_DEV

echo "==> Lancement de QEMU..."
qemu-system-i386 -drive file="$DISK_IMG",format=raw -m 256

