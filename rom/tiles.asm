;   __   __     __  __     __         __
;  /\ "-.\ \   /\ \/\ \   /\ \       /\ \
;  \ \ \-.  \  \ \ \_\ \  \ \ \____  \ \ \____
;   \ \_\\"\_\  \ \_____\  \ \_____\  \ \_____\
;    \/_/ \/_/   \/_____/   \/_____/   \/_____/
;   ______     ______       __     ______     ______     ______
;  /\  __ \   /\  == \     /\ \   /\  ___\   /\  ___\   /\__  _\
;  \ \ \/\ \  \ \  __<    _\_\ \  \ \  __\   \ \ \____  \/_/\ \/
;   \ \_____\  \ \_____\ /\_____\  \ \_____\  \ \_____\    \ \_\
;    \/_____/   \/_____/ \/_____/   \/_____/   \/_____/     \/_/
;
; https://joshbassett.info
; https://twitter.com/nullobject
; https://github.com/nullobject
;
; Copyright (c) 2020 Josh Bassett
;
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.

ROM_ADDR:   equ $0000 ; ROM address
WRAM_ADDR:  equ $4000 ; WRAM address
VRAM_ADDR:  equ $8000 ; VRAM address
STACK_ADDR: equ $8000 ; stack address

DISPLAY_SIZE: equ 64 ; pixels

DELAY_DURATION: equ $2000

MIN_TILE_INDEX: equ 48
MAX_TILE_INDEX: equ 91

TILE_INDEX: equ 0 ; tile index WRAM offset

  ld sp, STACK_ADDR
  di

; Load min tile index to RAM.
start:
  ld ix, WRAM_ADDR
  ld (ix+TILE_INDEX), MIN_TILE_INDEX

; Main loop.
loop:
  ld ix, WRAM_ADDR
  ld a, MAX_TILE_INDEX
  cp (ix+TILE_INDEX)    ; compare tile index to max
  jp z, start

  ld c, (ix+TILE_INDEX) ; load tile index into C
  inc (ix+TILE_INDEX)   ; increment tile index
  call blit_tile

  ld hl, DELAY_DURATION
  call delay

  jp loop

; Blit a tile to VRAM.
;
; c - tile code
blit_tile:
  ld h, 0             ; load tile code into HL
  ld l, c
  add hl, hl          ; shift left 6 bits (i.e. multiply by 64)
  add hl, hl
  add hl, hl
  add hl, hl
  add hl, hl
  add hl, hl
  ld bc, tiles        ; base tile address
  add hl, bc          ; add base tile address to offset
  ld bc, DISPLAY_SIZE ; number of bytes to copy
  ld de, VRAM_ADDR    ; start address
  ldir                ; transfer bytes from address HL to address DE
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
