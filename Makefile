parrot.o: parrot.asm
	nasm -f macho64 parrot.asm -o parrot.o

parrot: parrot.o
	gcc -m64 -o parrot parrot.o

clean: 
	rm parrot.o
	rm parrot
