section .data
  file db "navn.txt", 0
  mode db "r", 0
  hmsize equ 256
  fmt db "%s", 10, 0

section .text
  global _main

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

; return ptr to 
; 0: qword buffer ptr
; 8: qword size
readfile:
  push r15
  push r14
  push r13
  push r12
  push rbx

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

  ; return struct ptr
  mov rax, rbx

  pop rbx
  pop r12
  pop r13
  pop r14
  pop r15

  ret

; rdi: qword buffer ptr
; rsi: qword size
; return ptr to
; 0; qword array ptr
; 8: qword count
splitlines:
  push r15
  push r14
  push r13
  push r12
  push rbx

  push rdi
  push rsi

  ; allocate 16 bytes
  mov rdi, 16
  xor rax, rax
  call _malloc
  mov rbx, rax; struct ptr

  ; allocate array for line ptrs
  mov rdi, hmsize * 8
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
  ; return struct ptr
  mov rax, rbx

  pop rbx
  pop r12
  pop r13
  pop r14
  pop r15

  ret

; rdi: qword key ptr
; return ptr to
; 0: qword key ptr
; 8: qword next ptr
node_init:
  push r15
  push r14
  push r13
  push r12
  push rbx

  push rdi

  ; allocate 16 bytes
  mov rdi, 16
  xor rax, rax
  call _malloc
  mov rbx, rax

  pop rdi

  ; store key ptr
  mov [rbx], rdi

  ; set next to null
  mov qword [rbx + 8], 0

  ; return node ptr
  mov rax, rbx

  pop rbx
  pop r12
  pop r13
  pop r14
  pop r15

  ret

; rdi: qword key ptr
; return hash value in
; 0: qword hash value
hash_key:
  push r15
  push r14
  push r13
  push r12
  push rbx

  xor rax, rax; hash value

.loop:
  mov bl, [rdi]
  cmp bl, 0
  je .done

  ; update hash
  imul rax, 31
  add rax, rbx
  and rax, hmsize - 1

  ; next char
  inc rdi
  jmp .loop

.done:
  pop rbx
  pop r12
  pop r13
  pop r14
  pop r15

  ret

; return ptr to
; 0: qword array ptr
hashmap_init:
  push r15
  push r14
  push r13
  push r12
  push rbx

  ; allocate array for hashmap
  mov rdi, 8
  xor rax, rax
  call _malloc
  mov rbx, rax

  ; allocate buckets
  mov rdi, hmsize * 8
  xor rax, rax
  call _malloc
  mov [rbx], rax

  ; zero buckets
  xor rcx, rcx

.zero:
  cmp rcx, hmsize
  je .done

  ; load bucket ptr
  mov rdx, [rbx]
  imul rax, rcx, 8
  add rdx, rax

  ; set bucket to null
  mov qword [rdx], 0
  inc rcx
  jmp .zero

.done:
  mov rax, rbx

  pop rbx
  pop r12
  pop r13
  pop r14
  pop r15

  ret

; rdi: qword hashmap ptr
; rsi: qword key ptr
; no return
hashmap_insert:
  push r15
  push r14
  push r13
  push r12
  push rbx

  push rdi

  ; compute hash
  mov rdi, rsi
  xor rax, rax
  call hash_key
  mov r12, rax

  pop rdi

.try:
  ; load bucket ptr
  mov rdx, [rdi]
  imul rax, r12, 8
  add rdx, rax

  ; load node ptr
  mov rbx, [rdx]
  cmp rbx, 0
  je .insert

  ; collision
  jmp .done

.insert:
  push rdi
  push rdx

  ; create new node
  mov rdi, rsi
  xor rax, rax
  call node_init
  mov rbx, rax

  pop rdx
  pop rdi

  ; store node ptr in bucket
  mov [rdx], rbx

.done:
  pop rbx
  pop r12
  pop r13
  pop r14
  pop r15

  ret

; rdi: qword hashmap ptr
; no return
write_hashmap:
  push r15
  push r14
  push r13
  push r12
  push rbx

  xor rcx, rcx; index

.loop:
  cmp rcx, hmsize
  je .done

  ; load bucket ptr
  mov rdx, [rdi]
  imul rax, rcx, 8
  add rdx, rax

  ; load node ptr
  mov rbx, [rdx]
  cmp rbx, 0
  je .next

  push rdi
  push rcx

  ; print key
  lea rdi, [rel fmt]
  mov rsi, [rbx]
  xor rax, rax
  call _printf

  ; print next node value even if null
  lea rdi, [rel fmt]
  mov rsi, [rbx + 8]
  xor rax, rax
  call _printf

  pop rcx
  pop rdi

.next:
  inc rcx
  jmp .loop

.done:
  pop rbx
  pop r12
  pop r13
  pop r14
  pop r15

  ret

_main:
  ; read file
  xor rax, rax
  call readfile
  mov rbx, rax

  ; split data
  mov rdi, [rbx]
  mov rsi, [rbx + 8]
  xor rax, rax
  call splitlines
  mov rbx, rax

  ; init hashmap
  xor rax, rax
  call hashmap_init
  mov r12, rax

  xor rcx, rcx

.loop:
  mov rdx, [rbx + 8]
  cmp rcx, rdx
  jge .done

  ; load a line
  mov rax, [rbx]
  imul rdx, rcx, 8
  add rax, rdx

  push rcx

  ; insert line into hashmap
  mov rdi, r12
  mov rsi, [rax]
  xor rax, rax
  call hashmap_insert

  pop rcx

  inc rcx
  jmp .loop

.done:
  ; write hashmap
  mov rdi, r12
  xor rax, rax
  call write_hashmap

  mov rdi, 0
  call _exit
