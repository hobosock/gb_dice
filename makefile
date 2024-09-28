dice.gb : main.asm
	rgbasm -o main.o main.asm
	rgblink -o dice.gb main.o
	rgbfix -v -p 0xFF dice.gb
	rgblink -n dice.sym main.o
