echo build hash_api
nasm -f bin -O3 src/x64/find_api.asm -o bin/x64/find_api.bin
nasm -f bin -O3 src/x64/api_call.asm -o bin/x64/api_call.bin
nasm -f bin -O3 src/x86/find_api.asm -o bin/x86/find_api.bin
nasm -f bin -O3 src/x86/api_call.asm -o bin/x86/api_call.bin

echo build not_found
nasm -f bin -O3 test/not_found_x64.asm -o test/not_found_x64.bin
nasm -f bin -O3 test/not_found_x86.asm -o test/not_found_x86.bin

echo build assembly example
nasm -f bin -O3 example/asm/x64/find_api.asm -o example/asm/x64/find_api.bin
nasm -f bin -O3 example/asm/x64/api_call.asm -o example/asm/x64/api_call.bin
nasm -f bin -O3 example/asm/x64/win_exec.asm -o example/asm/x64/win_exec.bin
nasm -f bin -O3 example/asm/x86/find_api.asm -o example/asm/x86/find_api.bin
nasm -f bin -O3 example/asm/x86/api_call.asm -o example/asm/x86/api_call.bin
nasm -f bin -O3 example/asm/x86/win_exec.asm -o example/asm/x86/win_exec.bin
echo

echo test not_found
"bin/x64/scloader.exe" "test/not_found_x64.bin"
"bin/x86/scloader.exe" "test/not_found_x86.bin"
echo

echo test assembly example
"bin/x64/scloader.exe" "example/asm/x64/find_api.bin"
"bin/x64/scloader.exe" "example/asm/x64/api_call.bin"
"bin/x64/scloader.exe" "example/asm/x64/win_exec.bin"
"bin/x86/scloader.exe" "example/asm/x86/find_api.bin"
"bin/x86/scloader.exe" "example/asm/x86/api_call.bin"
"bin/x86/scloader.exe" "example/asm/x86/win_exec.bin"
echo

echo test Golang example on x64
export GOOS=windows
export GOARCH=amd64
go run test/test.go
go run example/go/main.go
echo

echo test Golang example on x86
export GOARCH=386
go run test/test.go
go run example/go/main.go
echo

echo clean test binary output files
rm ./test/*.bin