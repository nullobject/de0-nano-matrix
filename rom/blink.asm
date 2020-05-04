  ld sp, $2000 ; set stack pointer address
  ld hl, $2000 ; set gfx buffer address

loop:
  ld (hl), $00
  call delay
  ld (hl), $ff
  call delay
  jp loop

delay:
  ld de, $8000 ; wait for 1s
_delay:
  dec de
  ld a, d
  or e
  jp nz, _delay
  ret
