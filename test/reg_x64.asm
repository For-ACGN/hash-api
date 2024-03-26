; If all registers are not changed, rax is   0x22222222.
; If some registers are changed, rax is like 0x22122212.

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
  push rdi
  push rsi
  push rbx
  push rbp
  push r12
  push r13
  push r14
  push r15
%endmacro

%macro Test_Epilogue 0
  xor rcx, rcx

  cmp rdi, [rsp+7*8]
  je equal_1
  add rcx, 0x10000000
  jmp end_equal_1
  equal_1:
  add rcx, 0x20000000
  end_equal_1:

  cmp rsi, [rsp+6*8]
  je equal_2
  add rcx, 0x01000000
  jmp end_equal_2
  equal_2:
  add rcx, 0x02000000
  end_equal_2:

  cmp rbx, [rsp+5*8]
  je equal_3
  add rcx, 0x00100000
  jmp end_equal_3
  equal_3:
  add rcx, 0x00200000
  end_equal_3:

  cmp rbp, [rsp+4*8]
  je equal_4
  add rcx, 0x00010000
  jmp end_equal_4
  equal_4:
  add rcx, 0x00020000
  end_equal_4:

  cmp r12, [rsp+3*8]
  je equal_5
  add rcx, 0x00001000
  jmp end_equal_5
  equal_5:
  add rcx, 0x00002000
  end_equal_5:

  cmp r13, [rsp+2*8]
  je equal_6
  add rcx, 0x00000100
  jmp end_equal_6
  equal_6:
  add rcx, 0x00000200
  end_equal_6:

  cmp r14, [rsp+1*8]
  je equal_7
  add rcx, 0x00000010
  jmp end_equal_7
  equal_7:
  add rcx, 0x00000020
  end_equal_7:

  cmp r15, [rsp+0*8]
  je equal_8
  add rcx, 0x00000001
  jmp end_equal_8
  equal_8:
  add rcx, 0x00000002
  end_equal_8:

  add rsp, 8*8
  mov rax, rcx
%endmacro
