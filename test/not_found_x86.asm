[ORG 0]
[BITS 32]

entry:
  cld                                   ; clear the direction flag
  push 456                              ; push fake argument
  push 123                              ; push fake argument
  push 2                                ; push num arguments
  push 0xABCD1234                       ; push hash key
  push 0xABCD1234                       ; push function hash
  call api_call                         ; call api function
  test eax, eax                         ; check return value is zero
  jz not_found                          ;
  int3                                  ;
  not_found:                            ;
  ret                                   ; return to the caller

hash_api:
  %include "src/x86/api_call.asm"
