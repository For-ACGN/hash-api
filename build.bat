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

rem build develop tool
set GOOS=windows
set GOARCH=amd64
go build -v -trimpath -ldflags "-s -w" -o bin/x64/hash.exe hash/main.go
go build -v -trimpath -ldflags "-s -w" -o bin/x64/hexbin.exe hexbin/main.go
go build -v -trimpath -ldflags "-s -w" -o bin/x64/scloader.exe scloader/main.go
go build -v -trimpath -ldflags "-s -w" -o example/go/go_amd64.exe example/go/main.go
set GOARCH=386
go build -v -trimpath -ldflags "-s -w" -o bin/x86/hash.exe hash/main.go
go build -v -trimpath -ldflags "-s -w" -o bin/x86/hexbin.exe hexbin/main.go
go build -v -trimpath -ldflags "-s -w" -o bin/x86/scloader.exe scloader/main.go
go build -v -trimpath -ldflags "-s -w" -o example/go/go_386.exe example/go/main.go

set GOOS=linux
set GOARCH=amd64
go build -v -trimpath -ldflags "-s -w" -o bin/x64/hash hash/main.go
go build -v -trimpath -ldflags "-s -w" -o bin/x64/hexbin hexbin/main.go
set GOARCH=386
go build -v -trimpath -ldflags "-s -w" -o bin/x86/hash hash/main.go
go build -v -trimpath -ldflags "-s -w" -o bin/x86/hexbin hexbin/main.go