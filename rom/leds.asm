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
