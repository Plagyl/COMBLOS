OUTPUT_FORMAT(binary)
ENTRY(_start)

SECTIONS
{
  . = 0x9000;
  
  .text :
  {
    *(.text._start)
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
}

