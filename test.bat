echo off

rem build hash_api
nasm -f bin -O3 src/x64/find_api.asm -o bin/x64/find_api.bin
nasm -f bin -O3 src/x64/api_call.asm -o bin/x64/api_call.bin
nasm -f bin -O3 src/x86/find_api.asm -o bin/x86/find_api.bin
nasm -f bin -O3 src/x86/api_call.asm -o bin/x86/api_call.bin

rem build not_found
nasm -f bin -O3 test/not_found_x64.asm -o test/not_found_x64.bin
nasm -f bin -O3 test/not_found_x86.asm -o test/not_found_x86.bin

rem build example
nasm -f bin -O3 example/asm/x64/find_api.asm -o example/asm/x64/find_api.bin
nasm -f bin -O3 example/asm/x64/api_call.asm -o example/asm/x64/api_call.bin
nasm -f bin -O3 example/asm/x64/win_exec.asm -o example/asm/x64/win_exec.bin
nasm -f bin -O3 example/asm/x86/find_api.asm -o example/asm/x86/find_api.bin
nasm -f bin -O3 example/asm/x86/api_call.asm -o example/asm/x86/api_call.bin
nasm -f bin -O3 example/asm/x86/win_exec.asm -o example/asm/x86/win_exec.bin

rem test assembly
"bin/x64/scloader.exe" "test/not_found_x64.bin"
"bin/x86/scloader.exe" "test/not_found_x86.bin"

rem test example
"bin/x64/scloader.exe" "example/asm/x64/find_api.bin"
"bin/x64/scloader.exe" "example/asm/x64/api_call.bin"
"bin/x64/scloader.exe" "example/asm/x64/win_exec.bin"
"bin/x86/scloader.exe" "example/asm/x86/find_api.bin"
"bin/x86/scloader.exe" "example/asm/x86/api_call.bin"
"bin/x86/scloader.exe" "example/asm/x86/win_exec.bin"

set GOOS=windows
set GOARCH=amd64
go run test/test.go
go run example/go/main.go
set GOARCH=386
go run test/test.go
go run example/go/main.go

rem clean processes
taskkill /IM "win32calc.exe" /f

rem clean test binary output
del test\*.bin