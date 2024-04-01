echo off

rem build hash_api
nasm -f bin -O3 src/x64/find_api.asm -o bin/x64/find_api.bin
nasm -f bin -O3 src/x64/api_call.asm -o bin/x64/api_call.bin
nasm -f bin -O3 src/x86/find_api.asm -o bin/x86/find_api.bin
nasm -f bin -O3 src/x86/api_call.asm -o bin/x86/api_call.bin

rem build example
nasm -f bin -O3 example/asm/x64/find_api.asm -o example/asm/x64/find_api.bin
nasm -f bin -O3 example/asm/x64/api_call.asm -o example/asm/x64/api_call.bin
nasm -f bin -O3 example/asm/x64/win_exec.asm -o example/asm/x64/win_exec.bin
nasm -f bin -O3 example/asm/x86/find_api.asm -o example/asm/x86/find_api.bin
nasm -f bin -O3 example/asm/x86/api_call.asm -o example/asm/x86/api_call.bin
nasm -f bin -O3 example/asm/x86/win_exec.asm -o example/asm/x86/win_exec.bin

rem test example
"bin/x64/scloader.exe" -sc "example/asm/x64/find_api.bin"
"bin/x64/scloader.exe" -sc "example/asm/x64/api_call.bin"
"bin/x64/scloader.exe" -sc "example/asm/x64/win_exec.bin"
"bin/x86/scloader.exe" -sc "example/asm/x86/find_api.bin"
"bin/x86/scloader.exe" -sc "example/asm/x86/api_call.bin"
"bin/x86/scloader.exe" -sc "example/asm/x86/win_exec.bin"

set GOOS=windows
set GOARCH=amd64
go run test/test.go
go run example/go/main.go
set GOARCH=386
go run test/test.go
go run example/go/main.go

taskkill /IM "win32calc.exe" /f