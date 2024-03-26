; If all registers are not changed, rax is   0xFFFFFFFF.
; If some registers are changed, rax is like 0xFF1FFF1F.

; Example:
;
; %include "../../../test/reg_x64.asm"
;
; entry:
;  Test_Prologue
;  push rbx
;  shellcode
;  pop rbx
;  Test_Epilogue
;  ret
;

%macro Test_Prologue 0
  push rbx
  push rsi
  push rdi
  push rbp
  push r12
  push r13
  push r14
  push r15
%endmacro

%macro Test_Epilogue 0
  xor rcx, rcx

  cmp rbx, [rsp+7*8]
  jne equal_1
  add rcx, 0x00000002
  equal_1:
  add rcx, 0x0000000F

  cmp rsi, [rsp+6*8]
  jne equal_2
  add rcx, 0x00000010
  equal_2:

  cmp rdi, [rsp+5*8]
  jne equal_3
  add rcx, 0x00000100
  equal_3:

  cmp rbp, [rsp+4*8]
  jne equal_4
  add rcx, 0x00001000
  equal_4:

  cmp r13, [rsp+3*8]
  jne equal_5
  add rcx, 0x00010000
  equal_5:

  cmp r13, [rsp+2*8]
  jne equal_6
  add rcx, 0x00100000
  equal_6:

  cmp r14, [rsp+1*8]
  jne equal_7
  add rcx, 0x01000000
  equal_7:

  cmp r14, [rsp+0*8]
  jne equal_8
  add rcx, 0x10000000
  equal_8:

  add rsp, 8*8
  mov rax, rcx
%endmacro
