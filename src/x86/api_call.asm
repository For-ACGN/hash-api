; [original author: Stephen Fewer]
;
; stdcall calling convention:
;   https://learn.microsoft.com/en-us/cpp/cpp/stdcall
;
; register:
;   changed:   eax, ecx, edx.
;   unchanged: edi, esi, ebx, ebp, esp.
;
; build:
;   nasm -f bin -O3 api_call.asm -o api_call.bin
;
; note:
;   these functions assumes the direction flag has already been cleared via a CLD instruction.
;   these functions are unable to call forwarded exports.

[BITS 32]

section .data
  key_size EQU 4                        ; the hash key byte slice length
  ror_bit  EQU 4                        ; the number of the base ror bit
  ror_seed EQU ror_bit+1                ; the number of the seed hash ror bit
  ror_key  EQU ror_bit+2                ; the number of the hash key ror bit
  ror_mod  EQU ror_bit+3                ; the number of the module name hash ror bit
  ror_proc EQU ror_bit+4                ; the number of the procedure name hash ror bit

  reserve_stack EQU (3+2)*4             ; reserve stack size for store arguments and variables
  arg_mod_hash  EQU 0*4                 ; the stack offset of the argument module name hash
  arg_proc_hash EQU 1*4                 ; the stack offset of the argument procedure name hash
  arg_hash_key  EQU 2*4                 ; the stack offset of the argument hash key
  var_seed_hash EQU 3*4                 ; the stack offset of the variable seed hash
  var_key_hash  EQU 4*4                 ; the stack offset of the variable key hash

  args_offset EQU 3*4+4+4*4             ; stack offset to the original arguments on stack

; [input]  [stdcall] module hash, procedure hash, hash key and num api args.
;          then push the API parameters to the stack.
; [output] [eax = the return value from the API call].
api_call:
  ; try to find api address
  mov eax, [esp+1*4]                    ; read module name hash from stack
  mov ecx, [esp+2*4]                    ; read procedure name hash from stack
  mov edx, [esp+3*4]                    ; read hash key from stack
  push edx                              ; push hash key
  push ecx                              ; push procedure name hash
  push eax                              ; push module name hash
  call find_api                         ; call find api function

  ; check is find api function address
  test eax, eax                         ; check eax is zero
  jz not_found_api                      ;

  ; store context
  push edi                              ; store edi
  push esi                              ; store esi
  push ebp                              ; store ebp
  mov ebp, esp                          ; create new stack frame

  ; calculate the new stack size that need be allocated
  mov ecx, [ebp+args_offset-4]          ; read the number of arguments
  imul ecx, 4                           ; calculate new stack size
  sub esp, ecx                          ; reserve stack
  and esp, 0xFFFFFFF0                   ; ensure stack is 16 bytes aligned

  ; copy arguments to the new stack
  mov esi, ebp                          ; set source address
  add esi, args_offset                  ; add offset to target address
  mov edi, esp                          ; set destination address
  rep movsb                             ; copy parameters to new stack
  call eax                              ; call the api address

  ; restore context
  mov esp, ebp                          ; restore stack
  pop ebp                               ; restore rbp
  pop esi                               ; restore rsi
  pop edi                               ; restore rdi

 ; release stack that store input arguments
 not_found_api:                         ;
  pop edx                               ; save return address
  mov ecx, [esp+3*4]                    ; read the number of arguments
  add ecx, 4                            ; add (mod hash, proc hash, hash key, num args)
  imul ecx, 4                           ; calculate the stack size that need be release
  add esp, ecx                          ; restore stack
  push edx                              ; push return address
  ret                                   ; return to the caller

; [input]  [stdcall] module hash, procedure hash and hash key.
; [output] [eax = api function address].
find_api:
  ; store context
  push edi                              ; store edi
  push esi                              ; store esi
  push ebx                              ; store ebx
  push ebp                              ; store ebp

  ; reserve stack for store arguments and variables
  sub esp, reserve_stack                ; reserve stack
  mov ebp, esp                          ; for read arguments and variables easily in function

  ; set arguments and variables
  mov eax, [ebp+reserve_stack+5*4]      ; read module name hash from stack
  mov ecx, [ebp+reserve_stack+6*4]      ; read procedure name hash from stack
  mov edx, [ebp+reserve_stack+7*4]      ; read hash key from stack
  mov [ebp+arg_mod_hash], eax           ; store module name hash to stack
  mov [ebp+arg_proc_hash], ecx          ; store procedure name hash to stack
  mov [ebp+arg_hash_key], edx           ; store hash key to stack

  ; calculate seed hash
  xor ecx, ecx                          ; clear ecx
  mov edx, [ebp+arg_hash_key]           ; initialize edx for store seed hash
  lea esi, [ebp+arg_hash_key]           ; set address for load string byte
  mov cl, key_size                      ; set the loop times with hash key
 read_hash_key_0:                       ;
  xor eax, eax                          ; clear eax
  lodsb                                 ; load one byte from hash key
  ror edx, ror_seed                     ; rotate right the hash value
  add edx, eax                          ; add the next byte of hash key
  loop read_hash_key_0                  ; loop until read hash key finish
  mov [ebp+var_seed_hash], edx          ; save seed hash to stack

  ; calculate key hash
  mov edx, [ebp+var_seed_hash]          ; initialize edx for store key hash
  lea esi, [ebp+arg_hash_key]           ; set address for load string byte
  mov cl, key_size                      ; set the loop times with hash key
 read_hash_key_1:                       ;
  xor eax, eax                          ; clear eax
  lodsb                                 ; load one byte from hash key
  ror edx, ror_key                      ; rotate right the hash value
  add edx, eax                          ; add the next byte of hash key
  loop read_hash_key_1                  ; loop until read hash key finish
  mov [ebp+var_key_hash], edx           ; save key hash to stack

  ; get the first module
  mov ebx, [fs:0x18]                    ; get a pointer to the TEB
  mov ebx, [ebx+0x30]                   ; get TEB->PEB
  mov ebx, [ebx+0x0C]                   ; get PEB->LDR
  mov ebx, [ebx+0x14]                   ; get the first module from the InMemoryOrder module list
  call get_next_module                  ; begin find module and function

  ; restore stack for store arguments and variables
  add esp, reserve_stack                ; restore stack

  ; restore context
  pop ebp                               ; restore ebp
  pop ebx                               ; restore ebx
  pop esi                               ; restore esi
  pop edi                               ; restore edi
  ret 3*4                               ; return to the caller

get_next_module:
  mov edi, [ebp+var_seed_hash]          ; initialize edi for store module name hash
  mov esi, [ebx+40]                     ; get pointer to modules name (unicode string)
  test esi, esi                         ; check esi is zero
  jz not_found_func                     ; if zero get nex module is finish, but not found
  movzx ecx, word [ebx+38]              ; set ecx to the length we want to check
  sub ecx, 2                            ; set the loop times

 read_module_name:                      ;
  xor eax, eax                          ; clear eax
  lodsb                                 ; read in the next byte of the name
  cmp al, 'a'                           ; some versions of Windows use lower case module names
  jl uppercase_ok                       ;
  sub al, 0x20                          ; if so normalise to uppercase
  uppercase_ok:                         ;
  ror edi, ror_mod                      ; rotate right our hash value
  add edi, eax                          ; add the next byte of the name
  loop read_module_name                 ; loop until read module name finish

  ; check the module name hash
  add edi, [ebp+var_seed_hash]          ; add seed hash to module name hash
  add edi, [ebp+var_key_hash]           ; add key hash to module name hash
  cmp edi, [ebp+arg_mod_hash]           ; compare the module name hash
  jne get_next_mod_3

  ; proceed to iterate the export address table(EAT)
  push ebx                              ; save the current position in the module list for later
  mov ebx, [ebx+16]                     ; get this modules base address
  mov eax, [ebx+60]                     ; get PE header
  add eax, ebx                          ; add the modules base address
  mov eax, [eax+120]                    ; get the EAT from the PE header
  test eax, eax                         ; test if no export address table is present
  jz get_next_mod_2                     ; if no EAT present, process the next module
  add eax, ebx                          ; add the modules base address
  push eax                              ; save the current modules EAT
  mov ecx, [eax+24]                     ; get the number of function names
  mov edx, [eax+32]                     ; get the RVA of the function names
  add edx, ebx                          ; add the modules base address

 get_next_func:                         ; computing the module hash + function hash
  jecxz get_next_mod_1                  ; when we reach the start of the EAT, process the next module
  dec ecx                               ; decrement the function name counter
  mov esi, dword [edx+ecx*4]            ; get RVA of next module name
  add esi, ebx                          ; add the modules base address
  mov edi, [ebp+var_seed_hash]          ; initialize edi for store function name hash

 read_func_name:                       ; and compare it to the one we want
  xor eax, eax                          ; clear eax
  lodsb                                 ; read in the next byte of the ASCII function name
  test eax, eax                         ; check is null terminator
  je check_proc_hash                    ; finish procedure name hash
  ror edi, ror_proc                     ; rotate right our hash value
  add edi, eax                          ; add the next byte of the name
  cmp al, ah                            ; compare AL (the next byte from the name) to AH (null)
  jne read_func_name                    ; if we have not reached the null terminator, continue

 check_proc_hash:
  add edi, [ebp+var_seed_hash]          ; add seed hash to procedure name hash
  add edi, [ebp+var_key_hash]           ; add key hash to procedure name hash
  cmp edi, [ebp+arg_proc_hash]          ; compare the procedure name hash
  jne get_next_func                     ; go compute the next function hash if we have not found it
  jmp found_func                        ; if found, fix up stack, return the function address

 get_next_mod_1:                        ;
  pop eax                               ; pop off the current (now the previous) modules EAT
 get_next_mod_2:                        ;
  pop ebx                               ; restore our position in the module list
 get_next_mod_3:                        ;
  mov ebx, [ebx]                        ; get the next module
  jmp get_next_module                   ; process the next module

 found_func:                            ;
  pop eax                               ; restore the current modules EAT
  mov edx, dword [eax+36]               ; get the ordinal table RVA
  add edx, ebx                          ; add the modules base address
  mov cx, [edx+2*ecx]                   ; get the desired functions ordinal
  mov edx, dword [eax+28]               ; get the function addresses table RVA
  add edx, ebx                          ; add the modules base address
  mov eax, dword [edx+4*ecx]            ; get the desired functions RVA
  add eax, ebx                          ; add the modules base address to get the functions actual VA
  pop edx                               ; clear off the current position in the module list
  ret                                   ; return to the caller
 not_found_func:                        ;
  xor eax, eax                          ; clear the eax and it is the return value
  ret                                   ; return to the caller
