ROM_ADDR:   equ $0000 ; ROM address
WRAM_ADDR:  equ $4000 ; WRAM address
VRAM_ADDR:  equ $8000 ; VRAM address
STACK_ADDR: equ $8000 ; stack address

DISPLAY_SIZE: equ 64 ; pixels

DELAY_DURATION: equ $8000; 1 second

  di
  ld sp, STACK_ADDR

start:
  ld b, DISPLAY_SIZE ; number of bytes to copy
  ld c, $ff
  ld hl, VRAM_ADDR
  call fill

  ld bc, DELAY_DURATION
  call delay

  ld b, DISPLAY_SIZE ; number of bytes to copy
  ld c, $00
  ld hl, VRAM_ADDR
  call fill

  ld bc, DELAY_DURATION
  call delay

  jp start

; Fills a region of memory.
;
; b - address count
; c - fill value
; hl - start address
fill:
  ld (hl), c
  inc hl
  djnz fill
  ret

; Delays for a duration.
;
; bc - duration
delay:
  dec bc
  ld a, b
  or c
  jp nz, delay
  ret
