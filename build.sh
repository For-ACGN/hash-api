nasm -f bin -O3 src/x64/find_api.asm -o bin/x64/find_api.bin
nasm -f bin -O3 src/x64/api_call.asm -o bin/x64/api_call.bin
nasm -f bin -O3 src/x86/find_api.asm -o bin/x86/find_api.bin
nasm -f bin -O3 src/x86/api_call.asm -o bin/x86/api_call.bin
go build -v -trimpath -ldflags "-s -w" -o bin/hash hash/main.go