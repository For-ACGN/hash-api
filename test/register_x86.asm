; If all registers are not changed, eax is   0x2222.
; If some registers are changed, eax is like 0x2212.

; Example:
;
; %include "../../../test/reg_x86.asm"
;
; entry:
;  Test_Prologue
;  push ebx
;  shellcode
;  pop ebx
;  Test_Epilogue
;  ret
;

%macro Test_Prologue 0
  push edi
  push esi
  push ebx
  push ebp
%endmacro

%macro Test_Epilogue 0
  xor ecx, ecx

  cmp edi, [esp+3*4]
  je equal_1
  add ecx, 0x1000
  jmp end_equal_1
  equal_1:
  add ecx, 0x2000
  end_equal_1:

  cmp esi, [esp+2*4]
  je equal_2
  add ecx, 0x0100
  jmp end_equal_2
  equal_2:
  add ecx, 0x0200
  end_equal_2:

  cmp ebx, [esp+1*4]
  je equal_3
  add ecx, 0x0010
  jmp end_equal_3
  equal_3:
  add ecx, 0x0020
  end_equal_3:

  cmp ebp, [esp+0*4]
  je equal_4
  add ecx, 0x0001
  jmp end_equal_4
  equal_4:
  add ecx, 0x0002
  end_equal_4:

  add esp, 4*4
  mov eax, ecx
%endmacro
