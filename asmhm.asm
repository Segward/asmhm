section .bss
  buffer resb 4096
  lines resq 1024

section .data
  file db "navn.txt", 0
  mode db "r", 0
  fmt db "%s", 0

section .text
  global _main
  extern _printf
  extern _exit
  extern _fopen
  extern _fread
  extern _fclose

; arg1 string
; arg2 length
; arg3 lines array
; return: number of lines
_split_lines:
  xor rax, rax
  mov r8, rdi
  xor r9, r9 

.loop:
  cmp rsi, 0
  je .done

  ; check for newline
  mov bl, [rdi]
  cmp bl, 10
  jne .next_byte

  ; found newline
  mov byte [rdi], 0
  mov [rdx + r9*8], r8
  inc rax
  inc r9
  inc rdi
  dec rsi
  mov r8, rdi
  jmp .loop

.next_byte:
  inc rdi
  dec rsi
  jmp .loop

.done:
  ; handle last line if not empty
  cmp rdi, r8
  je .end

  mov [rdx + r9*8], r8
  inc rax

.end:
  ret

_main:
  ; fopen structure
  ; arg1: filename 
  ; arg2: mode
  ; return: FILE*
  lea rdi, [rel file]
  lea rsi, [rel mode]
  call _fopen
  
  ; store FILE* in r12
  mov r12, rax

  ; fread structure
  ; arg1: buffer
  ; arg2: size
  ; arg3: count
  ; arg4: FILE*
  ; return: number of items read
  lea rdi, [rel buffer]
  mov rsi, 1
  mov rdx, 4096
  mov rcx, r12
  call _fread

  ; store number of items read in r13
  mov r13, rax

  ; split lines
  ; arg1: buffer
  ; arg2: length
  ; arg3: lines array
  ; return: number of lines in rax
  lea rdi, [rel buffer]
  mov rsi, r13
  lea rdx, [rel lines]
  call _split_lines

  ; store number of lines in r14
  mov r14, rax

  ; fclose structure
  ; arg1: FILE*
  ; return: 0 if successful
  mov rdi, r12
  call _fclose

  ; exit program 
  mov rdi, r14
  call _exit
