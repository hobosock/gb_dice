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
  ld [wFrameCounter], a
  ld [wInputRead], a
  ld [wSelectedDigit], a
  ld [wModifierSign], a
  ld [wResult], a
  ld [wModifier], a
  ld a, 1
  ld [wNumberDice], a
  ld [wChangeDraw], a
  ld [wSDDraw], a
  ld [wNDDraw], a
  ld [wDSDraw], a
  ld [wMSDraw], a
  ld [wMDraw], a
  ld [wArrowDraw], a
  ld [wResultDraw], a
  ld a, 6
  ld [wDiceSides], a

Main:
  ; wait until it's not VBlank
  ld a, [rLY]
  cp 144
  jp nc, Main
WaitVBlank2:
  ld a, [rLY]
  cp 144
  jp c, WaitVBlank2

  call UpdateKeys

CheckA:
  ld a, [wNewKeys]
  and a, PADF_A
  jp z, CheckB
APress:
  ; on A press, wipe previous total
  ld a, 0
  ld [wResult], a
  ld a, 1 ; mark parts of screen for draw
  ld [wChangeDraw], a
  ld [wResultDraw], a
  call RollLogic
  jp Frame
CheckB:
  ld a, [wNewKeys]
  and a, PADF_B
  jp z, CheckLeft
BPress:
  ; on B press, keep previous total (sneak attack, etc.)
  ld a, 1 ; mark parts of screen for draw
  ld [wChangeDraw], a
  ld [wResultDraw], a
  call RollLogic
  jp Frame
CheckLeft: ; see if left button is pressed
  ld a, [wNewKeys]
  and a, PADF_LEFT ; left button bit
  jp z, CheckRight ; check next button if not pressed
Left: ; fall through if pressed
  ld a, 1 ; mark parts of screen for draw
  ld [wChangeDraw], a
  ld [wArrowDraw], a
  ld a, [wSelectedDigit] ; current position
  cp a, 0 ; compare with zero
  jp z, .wrapLeft ; wrap around if at 0
  dec a ; else decrement
  jp UpdateDigit
.wrapLeft:
  ld a, 3
  jp UpdateDigit
CheckRight:
  ld a, [wNewKeys]
  and a, PADF_RIGHT
  jp z, CheckUp ; restart loop if no key is pressed
Right: ; fall through if pressed
  ld a, 1 ; mark parts of screen for draw
  ld [wChangeDraw], a
  ld [wArrowDraw], a
  ld a, [wSelectedDigit]
  cp a, 3
  jp z, .wrapRight
  inc a
  jp UpdateDigit
.wrapRight:
  ld a, 0
  jp UpdateDigit
CheckUp:
  ld a, [wNewKeys]
  and a, PADF_UP
  jp z, CheckDown
Up:
  call MarkForRedraw
  ld a, [wSelectedDigit] ; see which digit to change
  call IncreaseDigit
  jp Frame
CheckDown:
  ld a, [wNewKeys]
  and a, PADF_DOWN
  jp z, Frame
  call MarkForRedraw
  ld a, [wSelectedDigit]
  call DecreaseDigit
  jp Frame

UpdateDigit:
  ld [wSelectedDigit], a

Frame:
  ; increment frame counter
  ld a, [wFrameCounter]
  inc a
  ld [wFrameCounter], a
  ;cp a, 20 ; every 15 frames (quarter of a second)
  ;jp nz, Main
  ; reset the frame counter back to 0
  ;ld a, 0
  ;ld [wFrameCounter], a

  ; if no change, no need to redraw!
  ld a, [wChangeDraw]
  cp a, 1
  jp nz, Main

  ; reset
  ld a, 0
  ld [wChangeDraw], a

  ; rendering stuff
  ld a, [wArrowDraw]
  cp a, 1
  jp nz, DrawNumberDice
  ld a, 0
  ld [wArrowDraw], a
  call DrawArrow

DrawNumberDice:
  ld a, [wNDDraw]
  cp a, 1
  jp nz, DrawDiceSides
  ld a, 0
  ld [wNDDraw], a ; reset
  ; draw number of dice
  ld a, [wNumberDice]
  call GetDigits
  ld hl, $9841 ; top left of tens place of number of dice
  ld a, [wTenPlace]
  call DigitDraw
  ld hl, $9843 ; you get it
  ld a, [wOnePlace]
  call DigitDraw

DrawDiceSides:
  ld a, [wDSDraw]
  cp a, 1
  jp nz, DrawModifier
  ld a, 0
  ld [wDSDraw], a
  ; draw dice sides
  ld a, [wDiceSides]
  call GetDigits
  ld hl, $9847
  ld a, [wTenPlace]
  call DigitDraw
  ld hl, $9849
  ld a, [wOnePlace]
  call DigitDraw

DrawModifier:
  ld a, [wMDraw]
  cp a, 1
  jp nz, DrawModifierSign
  ld a, 0
  ld [wMDraw], a
  ; draw modifier
  ld a, [wModifier]
  call GetDigits
  ld hl, $984C
  ld a, [wTenPlace]
  call DigitDraw
  ld hl, $984E
  ld a, [wOnePlace]
  call DigitDraw

DrawModifierSign:
  ld a, [wMSDraw]
  cp a, 1
  jp nz, DrawResult
  ld a, 0
  ld [wMSDraw], a
  ; draw plus/minus
  call DrawSign

DrawResult:
  ld a, [wResultDraw]
  cp a, 1
  jp nz, Main
  ld a, 0
  ld [wResultDraw], a
  ; draw result
  ld a, [wResult]
  call GetDigits
  ld hl, $996C
  ld a, [wHundredPlace]
  call DigitDraw
  ld hl, $996E
  ld a, [wTenPlace]
  call DigitDraw
  ld hl, $9970
  ld a, [wOnePlace]
  call DigitDraw

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

; identify correct digit to update and increase it
; no need to worry about wrapping, CPU handles that
IncreaseDigit:
  ld a, [wSelectedDigit]
  cp a, 0 ; number of dice
  jp nz, .dicesides
  ld a, [wNumberDice]
  inc a
  ld [wNumberDice], a
  jp .knownret
.dicesides: ; TODO: only increase to standard dice sizes
  cp a, 1 ; dice sides
  jp nz, .sign
  ld a, [wDiceSides]
  inc a
  ld [wDiceSides], a
  jp .knownret
.sign:
  cp a, 2 ; modifier
  jp nz, .modifier
  ld a, [wModifierSign]
  cp a, 0
  jp nz, .negative
  ld a, 1
  ld [wModifierSign], a
  jp .knownret
.negative:
  ld a, 0
  ld [wModifierSign], a
  jp .knownret
.modifier:
  ld a, [wModifier]
  inc a
  ld [wModifier], a
.knownret:
  ret

; identify correct digit to update and decrease it
; no need to worry about wrapping
DecreaseDigit:
  ld a, [wSelectedDigit]
  cp a, 0 ; number of dice
  jp nz, .dicesides
  ld a, [wNumberDice]
  dec a
  ld [wNumberDice], a
  jp .knownret
.dicesides:
  cp a, 1 ; dice sides
  jp nz, .sign
  ld a, [wDiceSides]
  dec a
  ld [wDiceSides], a
  jp .knownret
.sign:
  cp a, 2 ; modifier
  jp nz, .modifier
  ld a, [wModifierSign]
  cp a, 0
  jp nz, .negative
  ld a, 1
  ld [wModifierSign], a
  jp .knownret
.negative:
  ld a, 0
  ld [wModifierSign], a
  jp .knownret
.modifier:
  ld a, [wModifier]
  dec a
  ld [wModifier], a
.knownret:
  ret

; draw plus or minus sign
DrawSign:
  ld a, [wModifierSign]
  ld hl, $986B
  cp a, 1
  jp c, .plus
  ; draw minus
  ld [hl], 34
  jp .knownret
.plus:
  ; draw plus
  ld [hl], 33
  jp .knownret
.knownret:
  ret

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
  ld [hl], a
  ld hl, $9829 ; remove arrows
  ld a, 19
  ld [hl], a
  ld hl, $98A9
  ld a, 19
  ld [hl], a
  ld hl, $982B ; remove arrows
  ld a, 19
  ld [hl], a
  ld hl, $98AB
  ld a, 19
  ld [hl], a
  ld hl, $982E ; remove arrows
  ld a, 19
  ld [hl], a
  ld hl, $98AE
  ld a, 19
  ld [hl], a
  jp .end
.map1:
  ld hl, $9829
  ld a, 35
  ld [hl], a
  ld hl, $98A9
  ld a, 36
  ld [hl], a
  ld hl, $9823 ; remove arrows
  ld a, 19
  ld [hl], a
  ld hl, $98A3
  ld a, 19
  ld [hl], a
  ld hl, $982B ; remove arrows
  ld a, 19
  ld [hl], a
  ld hl, $98AB
  ld a, 19
  ld [hl], a
  ld hl, $982E ; remove arrows
  ld a, 19
  ld [hl], a
  ld hl, $98AE
  ld a, 19
  ld [hl], a
  jp .end
.map2:
  ld hl, $982B
  ld a, 35
  ld [hl], a
  ld hl, $98AB
  ld a, 36
  ld [hl], a
  ld hl, $9829 ; remove arrows
  ld a, 19
  ld [hl], a
  ld hl, $98A9
  ld a, 19
  ld [hl], a
  ld hl, $9823 ; remove arrows
  ld a, 19
  ld [hl], a
  ld hl, $98A3
  ld a, 19
  ld [hl], a
  ld hl, $982E ; remove arrows
  ld a, 19
  ld [hl], a
  ld hl, $98AE
  ld a, 19
  ld [hl], a
  jp .end
.map3:
  ld hl, $982E
  ld a, 35
  ld [hl], a
  ld hl, $98AE
  ld a, 36
  ld [hl], a
  ld hl, $9829 ; remove arrows
  ld a, 19
  ld [hl], a
  ld hl, $98A9
  ld a, 19
  ld [hl], a
  ld hl, $982B ; remove arrows
  ld a, 19
  ld [hl], a
  ld hl, $98AB
  ld a, 19
  ld [hl], a
  ld hl, $9823 ; remove arrows
  ld a, 19
  ld [hl], a
  ld hl, $98A3
  ld a, 19
  ld [hl], a
  jp .end
.end:
  ret

; NOTE: could do this cleaner by reserving 6 bytes for digit tiles
; then just write the appropriate values to those bytes for each number
; and only write out the address stuff once

; draws a 3x2 tile representation of a number 0-9
; @param hl: top left tile address
; @param a: number to draw
DigitDraw:
  cp a, 0
  jp nz, .one ; if b == 0, etc.
  ld [hl], 0 ; first tile
  inc hl
  ld [hl], 1 ; back too top left
  dec hl
  ld de, $20
  add hl, de ; shift down a row
  ld [hl], 2
  inc hl
  ld [hl], 3
  dec hl
  ld de, $20
  add hl, de
  ld [hl], 4
  inc hl
  ld [hl], 5
  jp .knownret
.one:
  cp a, 1
  jp nz, .two ; if b == 0, etc.
  ld [hl], 19 ; first tile
  inc hl
  ld [hl], 7 ; back too top left
  dec hl
  ld de, $20
  add hl, de ; shift down a row
  ld [hl], 19
  inc hl
  ld [hl], 3
  dec hl
  ld de, $20
  add hl, de
  ld [hl], 19
  inc hl
  ld [hl], 6
  jp .knownret
.two:
  cp a, 2
  jp nz, .three ; if b == 0, etc.
  ld [hl], 8 ; first tile
  inc hl
  ld [hl], 1 ; back too top left
  dec hl
  ld de, $20
  add hl, de ; shift down a row
  ld [hl], 9
  inc hl
  ld [hl], 10
  dec hl
  ld de, $20
  add hl, de
  ld [hl], 4
  inc hl
  ld [hl], 11
  jp .knownret
.three:
  cp a, 3
  jp nz, .four ; if b == 0, etc.
  ld [hl], 8 ; first tile
  inc hl
  ld [hl], 1 ; back too top left
  dec hl
  ld de, $20
  add hl, de ; shift down a row
  ld [hl], 14
  inc hl
  ld [hl], 18
  dec hl
  ld de, $20
  add hl, de
  ld [hl], 22
  inc hl
  ld [hl], 5
  jp .knownret
.four:
  cp a, 4
  jp nz, .five ; if b == 0, etc.
  ld [hl], 15 ; first tile
  inc hl
  ld [hl], 16 ; back too top left
  dec hl
  ld de, $20
  add hl, de ; shift down a row
  ld [hl], 17
  inc hl
  ld [hl], 18
  dec hl
  ld de, $20
  add hl, de
  ld [hl], 19
  inc hl
  ld [hl], 6
  jp .knownret
.five:
  cp a, 5
  jp nz, .six ; if b == 0, etc.
  ld [hl], 0 ; first tile
  inc hl
  ld [hl], 20 ; back too top left
  dec hl
  ld de, $20
  add hl, de ; shift down a row
  ld [hl], 17
  inc hl
  ld [hl], 21
  dec hl
  ld de, $20
  add hl, de
  ld [hl], 22
  inc hl
  ld [hl], 5
  jp .knownret
.six:
  cp a, 6
  jp nz, .seven ; if b == 0, etc.
  ld [hl], 0 ; first tile
  inc hl
  ld [hl], 20 ; back too top left
  dec hl
  ld de, $20
  add hl, de ; shift down a row
  ld [hl], 13
  inc hl
  ld [hl], 21
  dec hl
  ld de, $20
  add hl, de
  ld [hl], 4
  inc hl
  ld [hl], 5
  jp .knownret
.seven:
  cp a, 7
  jp nz, .eight ; if b == 0, etc.
  ld [hl], 8 ; first tile
  inc hl
  ld [hl], 1 ; back too top left
  dec hl
  ld de, $20
  add hl, de ; shift down a row
  ld [hl], 19
  inc hl
  ld [hl], 3
  dec hl
  ld de, $20
  add hl, de
  ld [hl], 19
  inc hl
  ld [hl], 6
  jp .knownret
.eight:
  cp a, 8
  jp nz, .nine ; if b == 0, etc.
  ld [hl], 0 ; first tile
  inc hl
  ld [hl], 1 ; back too top left
  dec hl
  ld de, $20
  add hl, de ; shift down a row
  ld [hl], 13
  inc hl
  ld [hl], 18
  dec hl
  ld de, $20
  add hl, de
  ld [hl], 4
  inc hl
  ld [hl], 5
  jp .knownret
.nine: ; don't need to check, should be 9 if you get here
  ld [hl], 0 ; first tile
  inc hl
  ld [hl], 1 ; back too top left
  dec hl
  ld de, $20
  add hl, de ; shift down a row
  ld [hl], 17
  inc hl
  ld [hl], 18
  dec hl
  ld de, $20
  add hl, de
  ld [hl], 22
  inc hl
  ld [hl], 5
  jp .knownret
.knownret:
  ret

; get the ones/tens/hundreds place digit
; @param b: original
; @output: wOnePlace, wTenPlace, wHundredPlace
GetDigits:
  ld c, 0 ; counter
.count100:
  sub a, 100 ; subtract 100
  inc c
  jp nc, .count100 ; if carry flag not set, repeat
  dec c ; adjust for 0/1/2 etc.
  ld d, a
  ld a, c
  ld [wHundredPlace], a ; store value
  ld a, d
  add a, 100 ; should be left with just 10s and 1s
  ld c, 0 ; reset counter
.count10:
  sub a, 10
  inc c
  jp nc, .count10
  dec c
  ld d, a
  ld a, c
  ld [wTenPlace], a
  ld a, d
  add a, 10
  ld c, 0
.count1:
  sub a, 1 ; NOTE: using sub instead of dec to get carry flag?
  inc c
  jp nc, .count1
  dec c
  ld a, c
  ld [wOnePlace], a
  ret

; figures out which digit on top screen to redraw
MarkForRedraw:
  ld a, [wSelectedDigit]
  cp a, 0
  jp nz, .one
  ld a, 1
  ld [wChangeDraw], a
  ld [wNDDraw], a
  jp .knownret
.one:
  cp a, 1
  jp nz, .two
  ld a, 1
  ld [wChangeDraw], a
  ld [wDSDraw], a
  jp .knownret
.two:
  cp a, 2
  jp nz, .three
  ld a, 1
  ld [wChangeDraw], a
  ld [wMSDraw], a
  jp .knownret
.three:
  ld a, 1
  ld [wChangeDraw], a
  ld [wMDraw], a
.knownret:
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
  db 32, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 31, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19
  db 29, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 30, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19
  db 26, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 27, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19
  db 26, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 00, 01, 00, 01, 00, 01, 19, 27, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19
  db 26, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 02, 03, 02, 03, 02, 03, 19, 27, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19
  db 26, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 04, 05, 04, 05, 04, 05, 19, 27, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19
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
wFrameCounter: db
wInputRead: db ; stops reading input for a while
wHundredPlace: db ; 3rd digit of number being drawn
wTenPlace: db ; 2nd digit
wOnePlace: db ;1st digit

SECTION "UX Data", WRAM0
wSelectedDigit: db
wNumberDice: db
wDiceSides: db
wModifierSign: db
wModifier: db
wResult: db
wChangeDraw: db ; set high if value changed and needs to be drawn
wSDDraw: db
wNDDraw: db
wDSDraw: db
wMSDraw: db
wMDraw: db
wArrowDraw: db
wResultDraw: db

SECTION "MathVariables", WRAM0
randstate:: ds 4

SECTION "Math", ROM0

;; From: https://github.com/pinobatch/libbet/blob/master/src/rand.z80#L34-L54
; Generates a pseudorandom 16-bit integer in BC
; using the LCG formula from cc65 rand():
; x[i + 1] = x[i] * 0x01010101 + 0xB3B3B3B3
; @return A=B=state bits 31-24 (which have the best entropy),
; C=state bits 23-16, HL trashed
rand::
  ; Add 0xB3 then multiply by 0x01010101
  ld hl, randstate+0
  ld a, [hl]
  add a, $B3
  ld [hl+], a
  adc a, [hl]
  ld [hl+], a
  adc a, [hl]
  ld [hl+], a
  ld c, a
  adc a, [hl]
  ld [hl], a
  ld b, a
  ret

; generates 4 random numbers
; subtracts dice side number until carry flag - essentially remainder
; adds 1 to remainder to get dice roll
; if more than 4 rolls are needed, generates 4 more
RollLogic:
  ; NOTE: don't clear previous result in this function
  ; NOTE: also, bound numbers somewhere else
  call rand ; generate numbers
  ld c, 0 ; roll counter
  ld a, [wNumberDice]
  ld d, a ; number of dice
.getrandom:
  call PickRand ; get a random number
  ld e, a ; store off random
  ld a, [wDiceSides]
  ld b, a ; sides
  ld a, e ; get random back
.remainder:
  sub a, b ; subtract number of sides
  jp nc, .remainder ; if not rollover, repeat
  add a, b ; roll back to remainder - this is die result - 1!
  inc a ; moves from 0 - (n-1) to 1 - n
  ld e, a
  ld a, [wResult]
  add a, e ; add to die result to total
  ld [wResult], a ; put back in memory
  dec d ; mark off a roll
  jp nz, .getrandom ; repeat process for next die if necessary
  ; otherwise add modifier and return
  ld a, [wModifierSign]
  cp a, 0 ; bonus
  jp nz, .penalty
  ld a, [wModifier]
  ld b, a
  ld a, [wResult]
  add a, b
  ld [wResult], a
  jp .knownret
.penalty:
  ld a, [wModifier]
  ld b, a
  ld a, [wResult]
  sub a, b
  ld [wResult], a
.knownret:
  ret


; picks which of 4 random numbers to use
; @param: c = numbers already used/counter from RollLogic
; @output: a = selected random number
PickRand:
  ld a, c
.zero:
  cp a, 0
  jp nz, .one
  ld a, [randstate]
  jp .knownret
.one:
  cp a, 1
  jp nz, .two
  ld a, [randstate + 1]
  jp .knownret
.two:
  cp a, 2
  jp nz, .three
  ld a, [randstate + 2]
  jp .knownret
.three:
  cp a, 3
  jp nz, .regen
  ld a, [randstate + 3]
  jp .knownret
.regen:
  call rand ; make new numbers
  ld a, 0 ; reset counter
  ld c, a
  jp PickRand
.knownret:
  ld b, a ; move random number
  ld a, c ; get counter back
  inc a ; increment counter
  ld c, a
  ld a, b ; put random number back in a
  ret
