section .bss
  buffer resb 4096
  lines resq 1024
  hashes resq 1024

section .data
  file db "navn.txt", 0
  mode db "r", 0
  nfmt db "%s", 10, 0
  hfmt db "%llx", 10, 0

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
split_lines:
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
  mov byte [rdi], 0
  mov [rdx + r9*8], r8
  inc rax
  inc r9

  ; move to next character
  inc rdi
  dec rsi
  mov r8, rdi
  jmp .loop

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
write_lines:
  ; r8: line index
  ; r9: lines array 
  ; r10: number of lines
  xor r8, r8
  mov r9, rdi
  mov r10, rsi
  
.loop:
  ; reached end of lines
  cmp r8, r10
  jge .done

  ; load line to rcx
  mov rcx, [r9 + r8*8]

  push r8
  push r9
  push r10

  ; print structure
  ; arg1: format
  ; arg2: line
  lea rdi, [rel nfmt]
  mov rsi, rcx
  xor rax, rax
  call _printf

  pop r10
  pop r9
  pop r8

  ; move to next line
  inc r8
  jmp .loop

.done:
  ret

; arg1: string
; return: hash
hash:
  xor rax, rax

.loop:
  ; load byte
  mov bl, [rdi]
  cmp bl, 0
  je .done

  ; update hash
  imul rax, rax, 31
  add rax, rbx
  and rax, 1023

  ; move to next byte
  inc rdi
  jmp .loop

.done:
  ret


; arg1: lines array
; arg2: number of lines
; arg3: hashes array
; return: void
hash_lines:
  ; r8: line index
  ; r9: lines array 
  ; r10: number of lines
  xor r8, r8
  mov r9, rdi
  mov r10, rsi
  
.loop:
  ; reached end of lines
  cmp r8, r10
  jge .done

  ; load line to rcx
  mov rcx, [r9 + r8*8]

  ; compute hash
  ; arg1: string
  ; return: hash
  mov rdi, rcx
  call hash

  push r8
  push r9
  push r10

  ; print structure
  ; arg1: format
  lea rdi, [rel hfmt]
  mov rsi, rax
  xor rax, rax
  call _printf

  pop r10
  pop r9
  pop r8

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
  call split_lines

  ; store number of lines in r13
  mov r13, rax

  ; write lines
  ; arg1: lines array
  ; arg2: number of lines
  lea rdi, [rel lines]
  mov rsi, r13
  call write_lines

  ; hash lines
  ; arg1: lines array
  ; arg2: number of lines
  ; arg3: hashes array
  lea rdi, [rel lines]
  mov rsi, r13
  lea rdx, [rel hashes]
  call hash_lines

  ; fclose structure
  ; arg1: FILE*
  ; return: 0 if successful
  mov rdi, r12
  call _fclose

  ; exit program 
  mov rdi, r13
  call _exit
