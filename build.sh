nasm -f bin -O3 src/x64/find_api.asm -o bin/x64/find_api.bin
nasm -f bin -O3 src/x64/api_call.asm -o bin/x64/api_call.bin
nasm -f bin -O3 src/x86/find_api.asm -o bin/x86/find_api.bin
nasm -f bin -O3 src/x86/api_call.asm -o bin/x86/api_call.bin

export GOOS=linux
export GOARCH=amd64
go build -v -trimpath -ldflags "-s -w" -o bin/x64/hash hash/main.go
export GOARCH=386
go build -v -trimpath -ldflags "-s -w" -o bin/x86/hash hash/main.go

export GOOS=windows
export GOARCH=amd64
go build -v -trimpath -ldflags "-s -w" -o bin/x64/hash.exe hash/main.go
export GOARCH=386
go build -v -trimpath -ldflags "-s -w" -o bin/x86/hash.exe hash/main.go