nasm -f bin -O3 src/x64/hash_api.asm -o bin/x64/hash_api.bin
nasm -f bin -O3 src/x64/find_api.asm -o bin/x64/find_api.bin
nasm -f bin -O3 src/x86/hash_api.asm -o bin/x86/hash_api.bin
nasm -f bin -O3 src/x86/find_api.asm -o bin/x86/find_api.bin
go build -v -trimpath -ldflags "-s -w" -o bin/hash.exe hash/main.go