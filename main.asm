INCLUDE "hardware.inc"

SECTION "Header", ROM0[$100]
  jp EntryPoint
  ds $150 - @, 0; make room for header, fill with 0s

SECTION "Graphics", ROM0
NumberTileData: incbin "numbers.bin",0,352

EntryPoint:
  ; do not turn the LCD off outside of VBlank
WaitVBlank:
  ld a, [rLY]
  cp 144
  jp c, WaitVBlank

  ; turn the LCD off
  ld a, 0
  ld [rLCDC], a

  ; copy tile data into VRAM
  ld de, NumberTileData
  ld hl, $9000
  ld bc, 352 ; not sure about this
  call Memcopy

  ; copy the tile map
  ld de, Tilemap
  ld hl, $9800
  ld bc, TilemapEnd - Tilemap
  call Memcopy

  ; turn the LCD on
  ld a, LCDCF_ON | LCDCF_BGON
  ld [rLCDC], a

  ; during the first (blank) frame, initialize display registers
  ld a, %11100100
  ld [rBGP], a

Loop:
  jp Loop

; copy bytes from one area to another
; @param de: source
; @param hl: destination
; @param bc: length
Memcopy:
  ld a, [de]
  ld [hli], a
  inc de
  dec bc
  ld a, b
  or a, c
  jp nz, Memcopy
  ret ; returns to the line function was called from

Tilemap:
  db $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  db $19, 00, 01, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  db $19, 13, 18, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  db $19, 04, 05, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  db $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  db $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  db $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  db $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  db $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  db $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  db $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  db $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  db $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  db $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  db $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  db $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  db $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  db $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, $19, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
TilemapEnd:

SECTION "Input Variables", WRAM0
wCurKeys: db ; reserve single byte
wNewKeys: db ; all buttons contained in single byte

SECTION "UX Data", WRAM0
wSelectedDigit: db
wNumberDice: db
wDiceSides: db
wModifierSign: db
wModifier: db
wResult: db
