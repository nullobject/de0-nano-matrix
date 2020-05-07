ROM_ADDR:   equ $0000 ; ROM address
WRAM_ADDR:  equ $4000 ; WRAM address
VRAM_ADDR:  equ $8000 ; VRAM address
STACK_ADDR: equ $8000 ; stack address

DISPLAY_SIZE: equ 64 ; pixels

DELAY_DURATION: equ $2000; 1 second

COUNTER: equ 0

  ld sp, STACK_ADDR
  di

start:
  ld ix, WRAM_ADDR
  ld (ix+COUNTER), 2 ; initialise counter

loop:
  ld ix, WRAM_ADDR
  ld c, (ix+COUNTER) ; load counter into B
  inc (ix+COUNTER)   ; increment counter
  call blit_tile

  ld hl, DELAY_DURATION
  call delay

  jp loop

; Blit a tile to the VRAM.
;
; c - tile code
blit_tile:
  ld h, 0
  ld l, c
  add hl, hl
  add hl, hl
  add hl, hl
  add hl, hl
  add hl, hl
  add hl, hl
  ld bc, tiles
  add hl, bc
  ld bc, DISPLAY_SIZE ; number of bytes to copy
  ld de, VRAM_ADDR    ; start address
  ldir                ; copy bytes from address DE to address HL
  ret

; Delays for a duration.
;
; hl - duration
delay:
  dec hl
  ld a, h
  or l
  jp nz, delay
  ret

tiles: incbin "tiles.hex"
