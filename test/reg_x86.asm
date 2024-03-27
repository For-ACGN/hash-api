; If all registers are not changed, eax is 0x1111.

; Prologue
push ebx
push esi
push edi
push ebp

; Code

; Epilogue
xor ecx, ecx

cmp ebx, [esp+3*4]
jne not_equal_1
add ecx, 0x0001
not_equal_1:

cmp esi, [esp+2*4]
jne not_equal_2
add ecx, 0x0010
not_equal_2:

cmp edi, [esp+1*4]
jne not_equal_3
add ecx, 0x0100
not_equal_3:

cmp ebp, [esp+0*4]
jne not_equal_4
add ecx, 0x1000
not_equal_4:

add esp, 4*4
mov eax, ecx
