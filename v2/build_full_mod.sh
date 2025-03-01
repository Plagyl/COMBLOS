#!/bin/bash
set -e

echo "[+] Nettoyage..."
rm -f os.img boot1.bin boot2.bin KERNEL.BIN

echo "[+] Compilation du kernel Rust..."
mkdir -p .cargo
cat > .cargo/config.toml << EOF
[build]
target = "i686-none.json"

[unstable]
build-std = ["core", "compiler_builtins"]
build-std-features = ["compiler-builtins-mem"]
EOF

RUSTFLAGS="-C target-feature=-sse" cargo +nightly build --release

if [ -f "target/i686-none/release/MONCOMBLE_OS" ]; then
    cp target/i686-none/release/MONCOMBLE_OS KERNEL.BIN
    echo "[+] Kernel compilé avec succès: $(du -h KERNEL.BIN)"
else
    echo "[-] Erreur: Le kernel n'a pas été compilé correctement."
    exit 1
fi

echo "[+] Assemblage du stage 1..."
nasm -f bin boot1.asm -o boot1.bin

echo "[+] Assemblage du stage 2..."
nasm -f bin boot2.asm -o boot2.bin

echo "[+] Création de l'image disque..."
dd if=/dev/zero of=os.img bs=1M count=10
dd if=boot1.bin of=os.img bs=512 count=1 conv=notrunc
dd if=boot2.bin of=os.img bs=512 seek=1 count=8 conv=notrunc
dd if=KERNEL.BIN of=os.img bs=512 seek=10 count=64 conv=notrunc

echo "[+] Image disque créée avec succès!"
echo "[+] Pour lancer QEMU :"
echo "    qemu-system-i386 -drive format=raw,file=os.img,index=0,media=disk -boot order=c"
