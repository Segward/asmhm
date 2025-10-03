nasm -f macho64 asmhm.asm -o asmhm.o
clang -target x86_64-apple-macos10.15 -o asmhm asmhm.o

