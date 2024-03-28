[ORG 0]
[BITS 64]

entry:
  ; store context
  push rbx                      ; store rbx

  ; calculate entry address
  call calc_entry_addr          ; calculate the entry address
  flag_CEA:                     ; flag for calculate entry address

  ; clear the direction flag
  cld

  ; find "kernel32.dll, WinExec"
  mov rcx, 0xCA2DBA870B222A04   ; set function hash
  mov rdx, 0xB725F01C80CE0985   ; set hash key
  call find_api                 ; try to find api address
  cmp rax, 0                    ; check target function is found
  jz not_found                  ;

  ; ensure stack is 16 bytes aligned
  push rdi                      ; store rdi
  mov rdi, rsp                  ; store current stack to rdi
  and rdi, 0xF                  ; calculate the offset
  sub rsp, rdi                  ; adjust current stack

  ; call "kernel32.dll, WinExec"
  xor rdx, rdx                  ; clear rdx
  lea rcx, [rbx+command]        ; lpCmdLine
  mov dl, [rbx+cmd_show]        ; uCmdShow
  sub rsp, 32                   ; reserve stack
  call rax                      ; call api function
  add rsp, 32                   ; restore stack

  ; restore aligned stack
  add rsp, rdi                  ; restore stack from rdi
  pop rdi                       ; restore rdi

  not_found:                    ;
  ; restore context
  pop rbx                       ; restore rbx
  ret                           ; return to the caller

; calculate shellcode entry address
calc_entry_addr:
  pop rax                       ; get return address
  lea rbx, [rax-flag_CEA]       ; calculate entry address.
  push rax                      ; push return address
  ret                           ; return to entry

hash_api:
  %include "../../../src/x64/find_api.asm"

command:
  db "calc.exe", 0

cmd_show:
  db 1
