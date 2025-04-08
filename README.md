# hash_api
Find&amp;Call Windows API by hash+key.

## Example
### x64
```nasm
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
  lea rbx, [rax-flag_CEA]               ; calculate entry address
  push rax                              ; push return address
  ret                                   ; return to entry

hash_api:
  %include "src/x64/api_call.asm"

command:
  db "calc.exe", 0

cmd_show:
  db 1
```

### x86
```nasm
[ORG 0]
[BITS 32]

entry:
  ; store context
  push ebx                              ; store ebx
  cld                                   ; clear the direction flag

  ; calculate entry address
  call calc_entry_addr                  ; calculate the entry address
  flag_CEA:                             ; flag for calculate entry address

  ; call "kernel32.dll, WinExec"
  lea edx, [ebx+command]                ; lpCmdLine
  xor ecx, ecx                          ; clear ecx
  mov cl, [ebx+cmd_show]                ; set uCmdShow
  push ecx                              ; push uCmdShow
  push edx                              ; push lpCmdLine
  push 2                                ; set num arguments
  push 0x61DA2999                       ; set hash key
  push 0x0AE20914                       ; set function hash
  call api_call                         ; call api function

  ; restore context
  pop ebx                               ; restore ebx
  ret                                   ; return to the caller

; calculate shellcode entry address
calc_entry_addr:
  pop eax                               ; get return address
  lea ebx, [eax-flag_CEA]               ; calculate entry address
  push eax                              ; push return address
  ret                                   ; return to entry

hash_api:
  %include "src/x86/api_call.asm"

command:
  db "calc.exe", 0

cmd_show:
  db 1
```
