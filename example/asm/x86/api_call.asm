[ORG 0]
[BITS 32]

entry:
  ; store context
  push ebx                              ; store ebx
  cld                                   ; clear the direction flag

  ; calculate entry address
  call calc_entry_addr                  ; calculate the entry address
  flag_CEA:                             ; flag for calculate entry address

  ; call "kernel32.dll, CreateThread"
  push 0                                ; lpThreadId
  push 0                                ; dwCreationFlags
  push ebx                              ; lpParameter, set entry address
  lea ecx, [ebx+win_exec]               ; calculate function address
  push ecx                              ; lpStartAddress
  push 0                                ; dwStackSize
  push 0                                ; lpThreadAttributes
  push 6                                ; set num arguments
  push 0x350B81FD                       ; set hash key
  push 0x0E1397A1                       ; set procedure name hash
  push 0x92E999D5                       ; set module name hash
  call api_call                         ; call api function

  ; call "kernel32.dll, WaitForSingleObject"
  push 1000                             ; set dwMilliseconds
  push eax                              ; set thread handle
  push 2                                ; set num arguments
  push 0xE58310AB                       ; set hash key
  push 0x0EDBA1DE                       ; set procedure name hash
  push 0x49D3C84A                       ; set module name hash
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

win_exec:
  ; store context
  push ebx                              ; store ebx
  mov ebx, [esp+2*4]                    ; read entry address from stack
  cld                                   ; clear the direction flag

  ; call "kernel32.dll, WinExec"
  lea ecx, [ebx+command]                ; lpCmdLine
  xor edx, edx                          ; clear ecx
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
  ret                                   ; exit thread

hash_api:
  %include "src/x86/api_call.asm"

command:
  db "calc.exe", 0

cmd_show:
  db 1
