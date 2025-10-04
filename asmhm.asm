; int _printf(char *fmt, ...);
extern _printf

; void _exit(int status);
extern _exit

; void *_malloc(size_t size);
extern _malloc

; void _free(void *ptr);
extern _free

section .text
  global _main

_main:
  ; allocate 16 bytes for two byte arrays
  mov rdi, 16
  xor rax, rax
  call _malloc
  mov rbx, rax

  ; store first byte array
  lea rax, [rel fmt1]
  mov [rbx], rax

  ; store second byte array
  lea rax, [rel fmt2]
  mov [rbx + 8], rax

  ; print first byte array
  mov rdi, [rbx]
  xor rax, rax
  call _printf

  ; print second byte array
  mov rdi, [rbx + 8]
  xor rax, rax
  call _printf

  mov rdi, 0
  call _exit

section .data
  fmt1 db "Hello, World!", 10, 0
  fmt2 db "Goodbye, World!", 10, 0
