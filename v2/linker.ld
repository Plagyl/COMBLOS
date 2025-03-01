OUTPUT_FORMAT(binary)
ENTRY(_start)
SECTIONS
{
  . = 0x100000;  /* Point d'entrée à 1MB */
  
  .text :
  {
    *(.text._start)  /* S'assurer que le point d'entrée est au début */
    *(.text*)
  }
  
  .rodata :
  {
    *(.rodata*)
  }
  
  .data :
  {
    *(.data*)
  }
  
  .bss :
  {
    *(.bss*)
    *(COMMON)
  }
  
  /DISCARD/ :
  {
    *(.comment)
    *(.eh_frame)
    *(.note.gnu.build-id)
  }
}
