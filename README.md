# Gameboy Dice
Gameboy Dice is an application for the Nintendo Gameboy that can be used to emulate dice rolls for table top RPG style games.  You can configure the number of dice, the number of sides, and add a bonus or penalty to the final roll.

Tested on BGB **only**.

## Instructions
The top half of the screen is dedicated to configuring the roll.  It uses a fairly standard die roll notation **A** d**B** +/- **C**.  **A** is the number of dice to roll, **B** is the number of sides the dice will have, and C is the penalty or modifier.

Use **left/right** on the D pad to select the number to modify.  **Up/down** on the D pad will change the selected number, or change the modifier from a bonus (add) to penalty (subtract).  Pressing **A** will roll the configured dice and display the total in the bottom half of the screen.  Pressing **B** will roll the configured dice and add the result to the existing total, handy for cases where you need to rull a combination of dice with different sides.

## Randomness
The rolls are semi-randomized using [Damian Yerrick's algorithm](https://github.com/pinobatch/libbet/blob/master/src/rand.z80#L34-L54).

## Build
The latest ROM and debug SYM file can be downloaded from the release section.  The files can be built using [RGBDS](https://rgbds.gbdev.io/) and the included make file.  You will need to download a copy of the [hardware.inc](https://github.com/gbdev/hardware.inc) file and place it in the main directory.

```
git clone https://github.com/hobosock/gb_dice
cd gb_dice
curl -o hardware.inc https://raw.githubusercontent.com/gbdev/hardware.inc/refs/heads/master/hardware.inc
make
```
