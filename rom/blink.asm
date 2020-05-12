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
