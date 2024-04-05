[ORG 0]
[BITS 64]

entry:
  cld                                   ; clear the direction flag
  mov rcx, 0xABCD1234ABCD1234           ; set function hash
  mov rdx, 0xABCD1234ABCD1234           ; set hash key
  mov r8, 2                             ; set num arguments
  mov r9, 123                           ; set fake arguments
  sub rsp, 32+1*8                       ; reserve stack
  call api_call                         ; call api function
  add rsp, 32+1*8                       ; restore stack
  test rax, rax                         ; check return value is zero
  jz not_found                          ;
  int3                                  ;
  not_found:                            ;
  ret                                   ; return to the caller

hash_api:
  %include "src/x64/api_call.asm"
