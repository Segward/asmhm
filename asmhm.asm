; int _printf(char *fmt, ...);
extern _printf

; void _exit(int status);
extern _exit

; void *_malloc(size_t size);
extern _malloc

; void _free(void *ptr);
extern _free

; FILE *_fopen(const char *filename, const char *mode);
extern _fopen

; size_t _fread(void *ptr, size_t size, size_t count, FILE *stream);
extern _fread

; int _fclose(FILE *stream);
extern _fclose

section .text
  global _main

; return ptr to 
; 0: qword buffer ptr
; 8: qword size
readfile:
  ; allocate 16 bytes
  mov rdi, 16
  xor rax, rax
  call _malloc
  mov rbx, rax; struct ptr

  ; allocate 4096 bytes buffer
  mov rdi, 4096
  xor rax, rax
  call _malloc
  mov [rbx], rax

  ; open file
  lea rdi, [rel file]
  lea rsi, [rel mode]
  xor rax, rax
  call _fopen
  mov r12, rax

  ; read file
  mov rdi, [rbx]
  mov rsi, 1
  mov rdx, 4096
  mov rcx, r12
  xor rax, rax
  call _fread
  mov [rbx + 8], rax

  ; close file
  mov rdi, r12
  xor rax, rax
  call _fclose

  ; return buffer ptr and size
  mov rax, rbx
  ret

; rdi: qword buffer ptr
; rsi: qword size
; return ptr to
; 0; qword array ptr
; 8: qword count
splitlines:
  push rdi
  push rsi

  ; allocate 16 bytes
  mov rdi, 16
  xor rax, rax
  call _malloc
  mov rbx, rax; struct ptr

  ; allocate 256 * 8 bytes array
  mov rdi, 256 * 8
  xor rax, rax
  call _malloc
  mov [rbx], rax

  pop rsi
  pop rdi

  ; set count to 0
  mov qword [rbx + 8], 0

  xor rcx, rcx; index in buffer

.loop:
  cmp rsi, 0
  je .done

  ; check for newline
  mov al, [rdi + rcx]
  cmp al, 10
  jne .next

  ; terminate line
  mov byte [rdi + rcx], 0

  ; load line ptr
  mov rdx, [rbx]
  mov rax, [rbx + 8]
  imul rax, 8
  add rdx, rax

  ; store line ptr
  lea rax, [rdi]
  mov [rdx], rax

  ; increment count
  inc qword [rbx + 8]

  ; move to next char
  add rdi, rcx
  inc rdi
  dec rsi
  xor rcx, rcx
  jmp .loop

.next:
  inc rcx
  dec rsi
  jmp .loop

.done:
  mov rax, rbx
  ret

_main:
  ; read file
  call readfile
  mov rbx, rax

  ; split data
  mov rdi, [rbx]
  mov rsi, [rbx + 8]
  call splitlines
  mov rbx, rax

  ; print number of lines
  lea rdi, [rel fmt]
  mov rsi, [rbx + 8]
  xor rax, rax
  call _printf

  ; load a line
  mov rcx, [rbx]
  add rcx, 8 * 117

  ; print second line
  lea rdi, [rel string]
  mov rsi, [rcx]
  xor rax, rax
  call _printf

  mov rdi, 0
  call _exit

section .data
  file db "navn.txt", 0
  mode db "r", 0
  fmt db "Number of lines: %d", 10, 0
  string db "%s", 10, 0
