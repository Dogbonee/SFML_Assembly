# SFML in Assembly
Utilizes the C binding of SFML 2.6.1. Not practical, but a fun assembly exercise.

# Building
To build you need the CSFML library and a NASM assembler.  
Then call  
`nasm -f elf64 -g main.asm`  
`gcc -m64 -no-pie main.o -o ASFML -L<path/to/CSFML>/lib/gcc -lcsfml-system -lcsfml-window -lcsfml-graphics`  
and run the executable generated.
