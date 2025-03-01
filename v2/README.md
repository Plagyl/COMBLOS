# MONCOMBLE_OS

## A Bare Metal Operating System with Native RAM Encryption

MONCOMBLE_OS is a custom operating system built from scratch that aims to provide a secure computing environment through native RAM encryption. This project serves as both an educational platform for OS development and a practical implementation of memory security concepts.

## Features

### Current Features
- Custom two-stage bootloader
- 32-bit protected mode kernel written in Rust
- Basic VGA text mode display
- PS/2 keyboard driver
- Simple command shell
- Memory management with slab allocator

### Planned Features
- **Native RAM encryption module** - Encrypt memory contents to protect against cold boot attacks
- Filesystem support
- Process scheduling
- User mode applications
- Networking stack
- Security features and hardening

## Building and Running

### Prerequisites
- Rust (nightly toolchain)
- NASM assembler
- QEMU for emulation
- Linux build environment

### Build Instructions
1. Clone the repository
   ```bash
   git clone https://github.com/yourusername/MONCOMBLE_OS.git
   cd MONCOMBLE_OS/v2
   ```

2. Build the operating system
   ```bash
   chmod +x build_full_mod.sh
   ./build_full_mod.sh
   ```

3. Run in QEMU
   ```bash
   qemu-system-i386 -drive format=raw,file=os.img,index=0,media=disk -boot order=c
   ```

### Alternative Run Methods
For better keyboard support in QEMU:
```bash
qemu-system-i386 -drive format=raw,file=os.img,index=0,media=disk -boot order=c -display sdl
```

Or with USB keyboard emulation:
```bash
qemu-system-i386 -drive format=raw,file=os.img,index=0,media=disk -boot order=c -usb -device usb-kbd
```

## Project Structure

```
v2/
├── boot1.asm          - First stage bootloader
├── boot2.asm          - Second stage bootloader (loads kernel)
├── build_full_mod.sh  - Build script
├── Cargo.toml         - Rust cargo configuration
├── config.toml        - Build configuration
├── i686-none.json     - Rust target specification
├── linker.ld          - Linker script for the kernel
└── src/
    ├── main.rs        - Kernel entry point
    ├── panic.rs       - Panic handler implementation
    ├── vga.rs         - VGA text mode driver
    ├── keyboard.rs    - Keyboard input handler
    ├── interrupts.rs  - Interrupt handling
    ├── shell.rs       - Command shell implementation
    └── memory/        - Memory management
        ├── mod.rs     - Memory module organization
        └── slab_allocator.rs - Slab memory allocation
```


## RAM Encryption Module (Planned)

The native RAM encryption module will provide:

- Transparent encryption of memory regions
- Protection against cold boot attacks and memory dumping
- Minimal performance impact through selective encryption
- Key management and secure boot integration

This feature aims to protect sensitive data from physical memory attacks where an attacker might attempt to read memory contents directly from RAM chips.

## Learning Resources

For those interested in OS development:
- [OSDev Wiki](https://wiki.osdev.org)
- [Philipp Oppermann's Blog](https://os.phil-opp.com/)
- [Rust Embedded Book](https://docs.rust-embedded.org/book/)
- [The Little Book About OS Development](https://littleosbook.github.io/)

## Contributing

Contributions are welcome! Feel free to:
- Report bugs and issues
- Suggest new features
- Submit pull requests
- Help with documentation


---

This project is a continual work in progress. As I develop the RAM encryption module and add new features, I'll update this README with progress and new instructions.
