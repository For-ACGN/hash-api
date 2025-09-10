[ORG 0]
[BITS 64]

entry:
  cld                                   ; clear the direction flag
  mov rcx, 0xABCD1234ABCD1234           ; set module name hash
  mov rdx, 0xABCD1234ABCD1234           ; set procedure name hash
  mov r8,  0xABCD1234ABCD1234           ; set hash key
  mov r9,  2                            ; set num arguments
  sub rsp, 32+2*8                       ; reserve stack
  call api_call                         ; call api function
  add rsp, 32+2*8                       ; restore stack
  test rax, rax                         ; check return value is zero
  jz not_found                          ;
  int3                                  ;
  not_found:                            ;
  ret                                   ; return to the caller

hash_api:
  %include "src/x64/api_call.asm"
