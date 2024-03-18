; [original author: Stephen Fewer]
;
; Windows stdcall calling convention:
; https://learn.microsoft.com/en-us/cpp/cpp/stdcall
; changed:   eax, ecx, edx.
; unchanged: ebx, ebp, esi, edi, esp.
;
; nasm -f bin -O3 find_api.asm -o find_api.bin
;
; these functions assumes the direction flag has already been cleared via a CLD instruction.
; these functions are unable to call forwarded exports.

[BITS 32]

section .data
  hash_key_size EQU 0x04

  ror_bit  EQU 0x000000004
  ror_seed EQU ror_bit + 1
  ror_key  EQU ror_bit + 2
  ror_mod  EQU ror_bit + 3
  ror_func EQU ror_bit + 4

  rsv_stack     EQU (2+4)*4
  arg_func_hash EQU 0*4
  arg_hash_key  EQU 1*4
  var_seed_hash EQU 2*4
  var_key_hash  EQU 3*4
  var_mod_hash  EQU 4*4
  var_func_hash EQU 5*4

; [input]  hash and hash key must be pushed onto stack.
; [output] [eax = api function address].
find_api:
  ; store context
  push ebx                      ; store ebx
  push esi                      ; store esi

  ; reserve stack for store arguments and variables
  sub esp, rsv_stack

  ; set arguments and variables
  mov ecx, [esp+rsv_stack+3*4]  ; read hash from stack
  mov [esp+arg_func_hash], ecx  ; store hash to stack
  mov ecx, [esp+rsv_stack+4*4]  ; read hash key from stack
  mov [esp+arg_hash_key], ecx   ; store hash key to stack
  xor eax, eax                  ; clear eax for clean stack
  mov [esp+var_seed_hash], eax  ; clean stack and store seed hash
  mov [esp+var_key_hash], eax   ; clean stack and store key hash
  mov [esp+var_mod_hash], eax   ; clean stack and store module name hash
  mov [esp+var_func_hash], eax  ; clean stack and store function name hash

  ; test register
  mov eax, [esp+arg_hash_key]

  ; restore stack for store arguments and variables
  add esp, rsv_stack

  ; restore context
  pop esi                       ; restore esi
  pop ebx                       ; restore ebx
  ret                           ; return to the caller

