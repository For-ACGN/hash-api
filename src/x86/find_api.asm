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
  push ebp                      ; store ebp
  push esi                      ; store esi
  push edi                      ; store edi

  ; reserve stack for store arguments and variables
  sub esp, rsv_stack

  ; set arguments and variables
  mov ecx, [esp+rsv_stack+5*4]  ; read hash from stack
  mov [esp+arg_func_hash], ecx  ; store hash to stack
  mov ecx, [esp+rsv_stack+6*4]  ; read hash key from stack
  mov [esp+arg_hash_key], ecx   ; store hash key to stack
  xor eax, eax                  ; clear eax for clean stack
  mov [esp+var_seed_hash], eax  ; clean stack for store seed hash
  mov [esp+var_key_hash], eax   ; clean stack for store key hash
  mov [esp+var_mod_hash], eax   ; clean stack for store module name hash
  mov [esp+var_func_hash], eax  ; clean stack for store function name hash

  ; for read arguments and variables on stack easily
  mov ebp, esp

  ; precompute hash
  call calc_seed_hash           ; initialize seed hash
  call calc_key_hash            ; initialize key hash

  ; get the first module
  mov ecx, 48                   ; set offset to ecx
  mov ebx, [fs:ecx]             ; get a pointer to the PEB
  mov ebx, [ebx+12]             ; get PEB->LDR
  mov ebx, [ebx+20]             ; get the first module from the InMemoryOrder module list
  call get_next_module          ; begin find module and function

  ; test register
  mov eax, edi

  ; restore stack for store arguments and variables
  add esp, rsv_stack

  ; restore context
  pop edi                       ; restore edi
  pop esi                       ; restore esi
  pop ebp                       ; restore ebp
  pop ebx                       ; restore ebx
  ret                           ; return to the caller

calc_seed_hash:
  mov edx, [ebp+arg_hash_key]   ; initialize edx for store seed hash
  lea esi, [ebp+arg_hash_key]   ; set address for load string byte
  mov ecx, hash_key_size        ; set the loop times with hash key
  read_hash_key_0:              ;
  xor eax, eax                  ; clear eax
  lodsb                         ; load one byte from hash key
  ror edx, ror_seed             ; rotate right the hash value
  add edx, eax                  ; add the next byte of hash key
  loop read_hash_key_0          ; loop until read hash key finish
  mov [ebp+var_seed_hash], edx  ; save seed hash to stack
  ret                           ; return to the caller

calc_key_hash:
  mov edx, [ebp+var_seed_hash]  ; initialize edx for store key hash
  lea esi, [ebp+arg_hash_key]   ; set address for load string byte
  mov ecx, hash_key_size        ; set the loop times with hash key
  read_hash_key_1:              ;
  xor eax, eax                  ; clear eax
  lodsb                         ; load one byte from hash key
  ror edx, ror_key              ; rotate right the hash value
  add edx, eax                  ; add the next byte of hash key
  loop read_hash_key_1          ; loop until read hash key finish
  mov [ebp+var_key_hash], edx   ; save key hash to stack
  ret                           ; return to the caller

get_next_module:
  mov edi, [ebp+var_seed_hash]  ; initialize edi for store module name hash
  mov esi, [ebx+40]             ; get pointer to modules name (unicode string)
  test esi, esi                 ; check esi is zero
  jz not_found_func             ; if zero get nex module is finish, but not found
  movzx ecx, word [ebx+38]      ; set ecx to the length we want to check

  read_module_name:             ;
  xor eax, eax                  ; clear eax
  lodsb                         ; read in the next byte of the name
  cmp al, 'a'                   ; some versions of Windows use lower case module names
  jl uppercase_ok               ;
  sub al, 0x20                  ; if so normalise to uppercase
  uppercase_ok:                 ;
  ror edi, ror_mod              ; rotate right our hash value
  add edi, eax                  ; add the next byte of the name
  loop read_module_name         ; loop until read module name finish
  mov [ebp+var_mod_hash], edi   ; store module name hash to the stack

  ; proceed to iterate the export address table(EAT)
  push ebx                      ; save the current position in the module list for later
  mov ebx, [ebx+16]             ; get this modules base address
  mov ecx, [ebx+60]             ; get PE header


  ; use ecx as our EAT pointer here.
  mov ecx, [ecx+ebx+120]        ; get the EAT from the PE header
  test ecx, ecx                 ; test if no export address table is present
  jz get_next_mod_0             ; if no EAT present, process the next module
  add ecx, ebx                  ; add the modules base address
  push ecx                      ; save the current modules EAT

  mov edx, [ecx+32]             ; get the RVA of the function names
  add edx, ebx                  ; add the modules base address
  mov ecx, [ecx+24]             ; get the number of function names



  get_next_mod_0:

  ; use ecx as our EAT pointer here so we can take advantage of jecxz.

  pop ecx
  pop ecx

  not_found_func:               ;
  xor eax, eax                  ; clear the eax and it is the return value
  ret                           ; return to the caller
