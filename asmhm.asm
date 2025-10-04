section .bss
  buffer resb 4096
  lines resq 1024
  hashmap resq 1024

section .data
  file db "navn.txt", 0
  mode db "r", 0
  fmt db "%s [%llx]", 10, 0
  hmsize equ 1024

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
  and rax, hmsize - 1

  ; move to next byte
  inc rdi
  jmp .loop

.done:
  ret

; arg1: hashmap array
; arg2: key
; return: void
hashmap_insert:
  push rdi

  ; compute hash
  mov rdi, rsi
  call hash

  pop rdi

.try:
  ; check for collision
  mov rbx, [rdi + rax*8]
  cmp rbx, 0
  je .done

  inc rax
  and rax, hmsize - 1
  jmp .try

.done:
  ; store key in hashmap
  mov [rdi + rax*8], rsi
  ret

; arg1: hashmap array
; arg2: lines array
; arg3: number of lines
; return: void
hashmap_insert_lines:
  ; r8: line index
  ; r9: lines array 
  ; r10: number of lines
  xor r8, r8
  mov r9, rsi
  mov r10, rdx

.loop:
  ; reached end of lines
  cmp r8, r10
  jge .done

  ; load line to rsi
  mov rsi, [r9 + r8*8]

  ; insert line into hashmap
  mov rdi, rdi
  call hashmap_insert

  ; move to next line
  inc r8
  jmp .loop

.done:
  ret

; arg1: hashmap array
; return: void
write_hashmap:
  ; r8: index
  xor r8, r8

.loop:
  ; reached end of hashmap
  cmp r8, 1024
  jge .done

  ; load entry to rsi
  mov rsi, [rdi + r8*8]
  cmp rsi, 0
  je .next

  ; get the hash from index
  mov rdx, r8
  imul rdx, rdx, 8

  push r8
  push rdi

  ; print structure
  ; arg1: format
  ; arg2: string
  ; arg3: hash
  lea rdi, [rel fmt]
  xor rax, rax
  call _printf

  pop rdi
  pop r8

.next:
  ; move to next entry
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

  ; insert lines into hashmap
  ; arg1: hashmap array
  ; arg2: lines array
  ; arg3: number of lines
  lea rdi, [rel hashmap]
  lea rsi, [rel lines]
  mov rdx, r13
  call hashmap_insert_lines

  ; write hashmap
  ; arg1: hashmap array
  lea rdi, [rel hashmap]
  call write_hashmap

  ; fclose structure
  ; arg1: FILE*
  ; return: 0 if successful
  mov rdi, r12
  call _fclose

  ; exit program 
  mov rdi, r13
  call _exit
