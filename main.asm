INCLUDE "hardware.inc"

SECTION "Header", ROM0[$100]
  jp EntryPoint
  ds $150 - @, 0; make room for header, fill with 0s

SECTION "Graphics", ROM0
NumberTileData: incbin "symbols.bin",0,592

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
  ld bc, 592 ; not sure about this
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

; initialize global variables
  ld a, 0
  ld [wSelectedDigit], a
  ld [wModifierSign], a
  ld [wResult], a
  ld [wModifier], a
  ld a, 1
  ld [wNumberDice], a
  ld a, 6
  ld [wDiceSides], a

Main:

  ; draw arrows in appropriate tile
DrawArrow:
  ld a, [wSelectedDigit]
  cp a, 3
  jp z, .map3
  cp a, 2
  jp z, .map2
  cp a, 1
  jp z, .map1
.map0: ; fall through
  ld hl, $9823 ; draw arrows
  ld a, 35
  ld [hl], a
  ld hl, $98A3
  ld a, 36
  ld [hl],a
  ld hl, $9829 ; remove arrows
  ld a, 19
  ld [hl], a
  ld hl, $98A9
  ld a, 19
  ld [hl],a
  ld hl, $982B ; remove arrows
  ld a, 19
  ld [hl], a
  ld hl, $98AB
  ld a, 19
  ld [hl],a
  ld hl, $982E ; remove arrows
  ld a, 19
  ld [hl], a
  ld hl, $98AE
  ld a, 19
  ld [hl],a
  jp .end
.map1:
  ld hl, $9829
  ld a, 35
  ld [hl], a
  ld hl, $98A9
  ld a, 36
  ld [hl],a
  ld hl, $9823 ; remove arrows
  ld a, 19
  ld [hl], a
  ld hl, $98A3
  ld a, 19
  ld [hl],a
  ld hl, $982B ; remove arrows
  ld a, 19
  ld [hl], a
  ld hl, $98AB
  ld a, 19
  ld [hl],a
  ld hl, $982E ; remove arrows
  ld a, 19
  ld [hl], a
  ld hl, $98AE
  ld a, 19
  ld [hl],a
  jp .end
.map2:
  ld hl, $982B
  ld a, 35
  ld [hl], a
  ld hl, $98AB
  ld a, 36
  ld [hl],a
  ld hl, $9829 ; remove arrows
  ld a, 19
  ld [hl], a
  ld hl, $98A9
  ld a, 19
  ld [hl],a
  ld hl, $9823 ; remove arrows
  ld a, 19
  ld [hl], a
  ld hl, $98A3
  ld a, 19
  ld [hl],a
  ld hl, $982E ; remove arrows
  ld a, 19
  ld [hl], a
  ld hl, $98AE
  ld a, 19
  ld [hl],a
  jp .end
.map3:
  ld hl, $982E
  ld a, 35
  ld [hl], a
  ld hl, $98AE
  ld a, 36
  ld [hl],a
  ld hl, $9829 ; remove arrows
  ld a, 19
  ld [hl], a
  ld hl, $98A9
  ld a, 19
  ld [hl],a
  ld hl, $982B ; remove arrows
  ld a, 19
  ld [hl], a
  ld hl, $98AB
  ld a, 19
  ld [hl],a
  ld hl, $9823 ; remove arrows
  ld a, 19
  ld [hl], a
  ld hl, $98A3
  ld a, 19
  ld [hl],a
  jp .end
.end:

  call UpdateKeys

CheckLeft: ; see if left button is pressed
  ld a, [wCurKeys]
  and a, PADF_LEFT ; left button bit
  jp z, CheckRight ; check next button if not pressed
Left: ; fall through if pressed
  ld a, [wSelectedDigit] ; current position
  cp a, 0 ; compare with zero
  jp z, .wrapLeft ; wrap around if at 0
  dec a ; else decrement
  jp UpdateDigit
.wrapLeft:
  ld a, 3
  jp UpdateDigit
CheckRight:
  ld a, [wCurKeys]
  and a, PADF_RIGHT
  jp z, Main ; restart loop if no key is pressed
Right: ; fall through if pressed
  ld a, [wSelectedDigit]
  cp a, 3
  jp z, .wrapRight
  inc a
  jp UpdateDigit
.wrapRight:
  ld a, 0
  jp UpdateDigit

UpdateDigit:
  ld [wSelectedDigit], a

  jp Main

UpdateKeys:
  ; poll half the controller
  ld a, P1F_GET_BTN
  call .onenibble
  ld b, a ; B7-4 = 1; B3=0 = unpressed buttons

  ; poll the other half
  ld a, P1F_GET_DPAD
  call .onenibble
  swap a ; A3-0 = unpressed buttons; A7-4 = 1
  xor a, b ; A = pressed buttons + directions
  ld b, a ; B = pressed buttons + directions

  ; and release the controller
  ld a, P1F_GET_NONE
  ldh [rP1], a

  ; combine with previous wCurKeys to make wNewKeys
  ld a, [wCurKeys]
  xor a, b; A = keys that changed state
  and a, b ; A = keys that changed to pressed
  ld [wNewKeys], a
  ld a, b
  ld [wCurKeys], a
  ret

.onenibble
  ldh [rP1], a ; switch the key matrix
  call .knownret ; burn 10 cycles calling a known ret
  ldh a, [rP1] ; ignore value while waiting for they key matrix to settle
  ldh a, [rP1]
  ldh a, [rP1] ; this read counts
  or a, $F0 ; A7-4 = 1; A3-0 = unpressed keys
.knownret
  ret

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
  db 29, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 30, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19
  db 26, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 27, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19
  db 26, 00, 01, 08, 01, 19, 19, 19, 07, 08, 01, 19, 00, 01, 15, 16, 19, 19, 19, 27, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19
  db 26, 02, 03, 14, 18, 19, 24, 19, 06, 09, 10, 33, 02, 03, 17, 18, 19, 19, 19, 27, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19
  db 26, 04, 05, 22, 05, 19, 23, 19, 06, 04, 11, 19, 04, 05, 19, 06, 19, 19, 19, 27, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19
  db 26, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 27, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19
  db 26, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 27, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19
  db 26, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 27, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19
  db 26, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 27, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19
  db 26, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 27, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19
  db 26, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 27, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19
  db 26, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 27, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19
  db 26, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 27, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19
  db 26, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 27, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19
  db 26, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 27, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19
  db 26, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 27, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19
  db 26, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 27, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19
  db 32, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 31, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19
  db 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19
  db 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19
  db 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19
  db 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19
  db 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19
  db 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19
  db 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19
  db 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19
  db 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19
  db 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19
  db 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19
  db 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19
  db 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19
  db 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19
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
