ROM_ADDR:   equ $0000 ; ROM address
WRAM_ADDR:  equ $4000 ; WRAM address
VRAM_ADDR:  equ $8000 ; VRAM address
STACK_ADDR: equ $8000 ; stack address

DISPLAY_SIZE: equ 64 ; pixels

DELAY_DURATION: equ $4000; 1 second

COUNTER: equ 0

  ld sp, STACK_ADDR
  di

start:
  ld ix, WRAM_ADDR
  ld (ix+COUNTER), 0 ; initialise counter

loop:
  ld ix, WRAM_ADDR
  ld a, (ix+COUNTER) ; load counter into A
  out ($00), a       ; write counter to LEDs
  inc (ix+COUNTER)   ; increment counter

  ld hl, DELAY_DURATION
  call delay

  jp loop

; Delays for a duration.
;
; hl - duration
delay:
  dec hl
  ld a, h
  or l
  jp nz, delay
  ret
