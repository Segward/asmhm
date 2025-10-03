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

; arg1: string
; arg2: length
; arg3: lines array
; return: number of lines
_split_lines:
  ; rax: line count 
  ; r8: start of current line
  ; r9: line index
  xor rax, rax
  mov r8, rdi
  xor r9, r9 

.loop:
  ; reached end of buffer
  cmp rsi, 0
  je .done

  ; check for newline
  cmp byte [rdi], 10
  jne .next

  ; store line start in lines array
  mov [rdx + r9*8], r8
  inc rax
  inc r9
  mov r8, rdi

.next:
  ; move to next character
  inc rdi
  dec rsi
  jmp .loop

.done:
  ; store last line if not empty
  cmp rdi, r8
  je .end

  ; store line start in lines array
  mov [rdx + r9*8], r8
  inc rax

.end:
  ret

; arg1: lines array
; arg2: number of lines
; return: void
_write_lines:
  ; r8: line index
  xor r8, r8
  
.loop:
  ; reached end of lines
  cmp r8, rsi
  jge .done

  ; load line to rcx
  mov rcx, [rdi + r8*8]

  ; print structure
  ; arg1: format
  ; arg2: line
  lea rdi, [rel fmt]
  mov rsi, rcx
  xor rax, rax
  call _printf

  ; move to next line
  inc r8
  jmp .loop

.done:
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

  ; store number of lines in r13
  mov r13, rax

  ; write lines
  ; arg1: lines array
  ; arg2: number of lines
  lea rdi, [rel lines]
  mov rsi, r13
  call _write_lines

  ; fclose structure
  ; arg1: FILE*
  ; return: 0 if successful
  mov rdi, r12
  call _fclose

  ; exit program 
  mov rdi, r13
  call _exit
