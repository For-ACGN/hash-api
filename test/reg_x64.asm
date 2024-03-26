; If all registers are not changed, rax is 0x11111111.

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
  jne not_equal_1
  add rcx, 0x00000001
  not_equal_1:

  cmp rsi, [rsp+6*8]
  jne not_equal_2
  add rcx, 0x00000010
  not_equal_2:

  cmp rdi, [rsp+5*8]
  jne not_equal_3
  add rcx, 0x00000100
  not_equal_3:

  cmp rbp, [rsp+4*8]
  jne not_equal_4
  add rcx, 0x00001000
  not_equal_4:

  cmp r13, [rsp+3*8]
  jne not_equal_5
  add rcx, 0x00010000
  not_equal_5:

  cmp r13, [rsp+2*8]
  jne not_equal_6
  add rcx, 0x00100000
  not_equal_6:

  cmp r14, [rsp+1*8]
  jne not_equal_7
  add rcx, 0x01000000
  not_equal_7:

  cmp r14, [rsp+0*8]
  jne not_equal_8
  add rcx, 0x10000000
  not_equal_8:

  add rsp, 8*8
  mov rax, rcx
%endmacro
