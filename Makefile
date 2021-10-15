bo: bo.o	
	gcc -o bo bo.o -no-pie -g
bo.o: bo.asm
	nasm -felf64 bo.asm -o bo.o
clean:
	rm bo.o
