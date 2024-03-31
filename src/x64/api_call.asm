; [original author: Stephen Fewer]
;
; x64 calling convention:
;   https://learn.microsoft.com/en-us/cpp/build/x64-calling-convention
;
; x64 software conventions:
;   https://learn.microsoft.com/en-us/cpp/build/x64-software-conventions#x64-register-usage
;
; register:
;   changed:   rax, rcx, rdx, r8, r9, r10, r11.
;   unchanged: rdi, rsi, rbx, rbp, rsp, r12, r13, r14, r15.
;
; build:
;   nasm -f bin -O3 api_call.asm -o api_call.bin
;
; note:
;   these functions assumes the direction flag has already been cleared via a CLD instruction.
;   these functions are unable to call forwarded exports.

[BITS 64]

section .data
  hash_key_size EQU 0x08                ; the hash key byte slice length

  ror_bit  EQU 0x000000008              ; the number of the base ror bit
  ror_seed EQU ror_bit + 1              ; the number of the seed hash ror bit
  ror_key  EQU ror_bit + 2              ; the number of the hash key ror bit
  ror_mod  EQU ror_bit + 3              ; the number of the module name hash ror bit
  ror_func EQU ror_bit + 4              ; the number of the function name hash ror bit

  args_offset EQU (3+1)*8+32            ; stack offset to the original arguments on stack

; [input]  [rcx = hash], [rdx = hash key], [r8 = num api args]
; api args [r9 = (rcx)], stack: rdx, r8, r9 and any stack params).
; [output] [rax = the return value from the API call].
api_call:
  ; try to find api address
  push r8                               ; store r8
  push r9                               ; store r9
  call find_api                         ; call find api function
  pop r9                                ; restore rcx
  pop r8                                ; restore rdx

  ; check is find api function address
  test rax, rax                         ; check rax is zero
  jz not_found_api                      ;
  ; store context
  push rdi                              ; store rdi
  push rsi                              ; store rsi
  push rbp                              ; store rbp
  mov rbp, rsp                          ; create new stack frame

  ; calculate new stack size that need alloc
  imul r8, 8                            ; calculate new stack size
  sub rsp, r8                           ; reserve stack
  and rsp, 0xFFFFFFFFFFFFFFF0           ; ensure stack is 16 bytes aligned

  ; copy arguments to the new stack
  mov rsi, rbp                          ; set source address
  add rsi, args_offset+3*8              ; add offset to target address
  mov rdi, rsp                          ; set destination address
  mov rcx, r8                           ; set num bytes
  rep movsb                             ; copy parameters to new stack
  ; move arguments about api
  mov rcx, r9                           ; set rcx from r9
  mov rdx, [rbp+args_offset+0*8]        ; set rdx from stack
  mov r8, [rbp+args_offset+1*8]         ; set r8 from stack
  mov r9, [rbp+args_offset+2*8]         ; set r9 from stack
  ; call api function
  sub rsp, 32                           ; reserve stack
  call rax                              ; call the api address
  add rsp, 32                           ; restore stack

  ; restore context
  mov rsp, rbp                          ; restore stack
  pop rbp                               ; restore rbp
  pop rsi                               ; restore rsi
  pop rdi                               ; restore rdi
  not_found_api:                        ;
  ret                                   ; return to the caller

; [input]  [rcx = hash], [rdx = hash key].
; [output] [rax = api function address].
find_api:
  ; store context
  push rsi                              ; store rsi
  push rbx                              ; store rbx
  push r12                              ; store seed hash
  push r13                              ; store key hash
  push r14                              ; store module name hash
  push r15                              ; store function name hash

  ; store arguments
  mov r8, rcx                           ; function hash
  mov r9, rdx                           ; hash key

  ; precompute hash
  call calc_seed_hash                   ; initialize seed hash
  call calc_key_hash                    ; initialize key hash

  ; get the first module
  mov rcx, 96                           ; set offset to rcx
  mov rbx, [gs:rcx]                     ; get a pointer to the PEB
  mov rbx, [rbx+24]                     ; get PEB->LDR
  mov rbx, [rbx+32]                     ; get the first module from the InMemoryOrder module list
  call get_next_module                  ; begin find module and function

  ; restore context
  pop r15                               ; restore r15
  pop r14                               ; restore r14
  pop r13                               ; restore r13
  pop r12                               ; restore r12
  pop rbx                               ; restore rbx
  pop rsi                               ; restore rsi
  ret                                   ; return to the caller

calc_seed_hash:
  mov r12, r9                           ; initialize r12 for store seed hash
  push r9                               ; push hash key to stack
  mov rsi, rsp                          ; set address for load string byte
  mov rcx, hash_key_size                ; set the loop times with hash key
  read_hash_key_0:                      ;
  xor rax, rax                          ; clear rax
  lodsb                                 ; load one byte from hash key
  ror r12, ror_seed                     ; rotate right the hash value
  add r12, rax                          ; add the next byte of hash key
  loop read_hash_key_0                  ; loop until read hash key finish
  pop r9                                ; restore stack
  ret                                   ; return to the caller

calc_key_hash:
  mov r13, r12                          ; initialize r13 for store key hash
  push r9                               ; push hash key to stack
  mov rsi, rsp                          ; set address for load string byte
  mov rcx, hash_key_size                ; set the loop times with hash key
  read_hash_key_1:                      ;
  xor rax, rax                          ; clear rax
  lodsb                                 ; load one byte from hash key
  ror r13, ror_key                      ; rotate right the hash value
  add r13, rax                          ; add the next byte of hash key
  loop read_hash_key_1                  ; loop until read hash key finish
  pop r9                                ; restore stack
  ret                                   ; return to the caller

get_next_module:
  mov r14, r12                          ; initialize r14 for store module name hash
  mov rsi, [rbx+80]                     ; get pointer to modules name (unicode string)
  test rsi, rsi                         ; check rsi is zero
  jz not_found_func                     ; if zero get nex module is finish, but not found
  movzx rcx, word [rbx+74]              ; set rcx to the length we want to check

  read_module_name:                     ;
  xor rax, rax                          ; clear rax
  lodsb                                 ; read in the next byte of the name
  cmp al, 'a'                           ; some versions of Windows use lower case module names
  jl uppercase_ok                       ;
  sub al, 0x20                          ; if so normalise to uppercase
  uppercase_ok:                         ;
  ror r14, ror_mod                      ; rotate right our hash value
  add r14, rax                          ; add the next byte of the name
  loop read_module_name                 ; loop until read module name finish

  ; proceed to iterate the export address table(EAT)
  push rbx                              ; save the current position in the module list for later
  mov rbx, [rbx+32]                     ; get this modules base address
  mov eax, dword [rbx+60]               ; get PE header
  add rax, rbx                          ; add the modules base address

  ; this test case covers when running on wow64 but in a native x64
  ; context via native_x64.asm and their may be a PE32 module present
  ; in the PEB module list, (typically the main module). as we are
  ; using the win64 PEB ([gs:96]) we wont see the wow64 modules present
  ; in the win32 PEB ([fs:48])
  cmp word [rax+24], 0x020B             ; is this module actually a PE64 executable?
  jne get_next_mod_2                    ; if not, proceed to the next module
  mov eax, dword [rax+136]              ; get export tables RVA
  test rax, rax                         ; test if no export address table is present
  jz get_next_mod_2                     ; if no EAT present, process the next module
  add rax, rbx                          ; add the modules base address
  push rax                              ; save the current modules EAT
  mov ecx, dword [rax+24]               ; get the number of function names
  mov edx, dword [rax+32]               ; get the RVA of the function names
  add rdx, rbx                          ; add the modules base address

  get_next_func:                        ; computing the module hash + function hash
  jrcxz get_next_mod_1                  ; when we reach the start of the EAT, process the next module
  dec rcx                               ; decrement the function name counter
  mov esi, dword [rdx+rcx*4]            ; get RVA of next module name
  add rsi, rbx                          ; add the modules base address
  mov r15, r12                          ; initialize r15 for store module name hash

  read_func_name:                       ; and compare it to the one we want
  xor rax, rax                          ; clear rax
  lodsb                                 ; read in the next byte of the ASCII function name
  ror r15, ror_func                     ; rotate right our hash value
  add r15, rax                          ; add the next byte of the name
  cmp al, ah                            ; compare AL (the next byte from the name) to AH (null)
  jne read_func_name                    ; if we have not reached the null terminator, continue

  ; calculate the finally hash
  add r15, r14                          ; add the current module hash to the function hash
  add r15, r13                          ; add the key hash to the function hash
  add r15, r12                          ; add the seed hash to the function hash
  cmp r8, r15                           ; compare the hash to the one we are searching for
  jnz get_next_func                     ; go compute the next function hash if we have not found it
  jmp found_func                        ; if found, fix up stack, return the function address

  get_next_mod_1:                       ;
  pop rax                               ; pop off the current (now the previous) modules EAT
  get_next_mod_2:                       ;
  pop rbx                               ; restore our position in the module list
  mov rbx, [rbx]                        ; get the next module
  jmp get_next_module                   ; process the next module

  found_func:                           ;
  pop rax                               ; restore the current modules EAT
  mov edx, dword [rax+36]               ; get the ordinal table RVA
  add rdx, rbx                          ; add the modules base address
  mov cx, [rdx+2*rcx]                   ; get the desired functions ordinal
  mov edx, dword [rax+28]               ; get the function addresses table RVA
  add rdx, rbx                          ; add the modules base address
  mov eax, dword [rdx+4*rcx]            ; get the desired functions RVA
  add rax, rbx                          ; add the modules base address to get the functions actual VA
  pop rdx                               ; clear off the current position in the module list
  ret                                   ; return to the caller
  not_found_func:                       ;
  xor rax, rax                          ; clear the rax and it is the return value
  ret                                   ; return to the caller
