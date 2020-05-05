STACK_ADDR: equ $2000 ; stack address
VRAM_ADDR: equ $2000 ; VRAM address
NUM_LEDS: equ 64 ; number of LEDs
DELAY_DURATION: equ $8000; 1 second

  di
  ld sp, STACK_ADDR

start:
  ld b, NUM_LEDS
  ld c, $ff
  ld hl, VRAM_ADDR
  call fill

  ld bc, DELAY_DURATION
  call delay

  ld b, NUM_LEDS
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
