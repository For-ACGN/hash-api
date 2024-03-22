package main

import (
	"fmt"
	"log"
	"os"
	"runtime"
	"syscall"
	"unsafe"

	"golang.org/x/sys/windows"

	"github.com/For-ACGN/hash-api/rorwk"
)

func main() {
	testFindAPI()
	testAPICall()
	fmt.Println("all tests passed!")
}

func testFindAPI() {
	findAPI := loadShellcode("find_api")
	hash, key := calcHash("kernel32.dll", "ReadProcessMemory")
	fmt.Printf("hash: 0x%08X\n", hash)
	fmt.Printf("key:  0x%08X\n", key)

	apiAddr, _, err := syscall.SyscallN(findAPI, hash, key)
	fmt.Println(err)
	proc := windows.NewLazySystemDLL("kernel32.dll").NewProc("ReadProcessMemory").Addr()
	if proc != apiAddr {
		log.Fatalf("expected address: 0x%08X, actual: 0x%08X\n", proc, apiAddr)
	}

	hash, key = calcHash("invalid.dll", "ReadProcessMemory")
	apiAddr, _, err = syscall.SyscallN(findAPI, hash, key)
	fmt.Println(err)
	if apiAddr != 0 {
		log.Fatalln("unexpected return value:", apiAddr)
	}

	hash, key = calcHash("kernel32.dll", "Invalid")
	apiAddr, _, err = syscall.SyscallN(findAPI, hash, key)
	fmt.Println(err)
	if apiAddr != 0 {
		log.Fatalln("unexpected return value:", apiAddr)
	}
}

func testAPICall() {
	apiCall := loadShellcode("api_call")
	hash, key := calcHash("kernel32.dll", "CreateThread")
	fmt.Printf("hash: 0x%08X\n", hash)
	fmt.Printf("key:  0x%08X\n", key)
	var threadID uint32
	handle, _, err := syscall.SyscallN(
		apiCall, hash, key,
		0, 0, apiCall, 0, windows.CREATE_SUSPENDED,
		uintptr(unsafe.Pointer(&threadID)),
	)
	fmt.Println(err)
	fmt.Printf("handle: 0x%08X\n", handle)

	e := windows.CloseHandle(windows.Handle(handle))
	if e != nil {
		log.Fatalln("failed to close thread handle:", err)
	}
	fmt.Println("thread id:", threadID)
}

func loadShellcode(name string) uintptr {
	var (
		shellcode []byte
		err       error
	)
	switch runtime.GOARCH {
	case "amd64":
		shellcode, err = os.ReadFile(fmt.Sprintf("bin/x64/%s.bin", name))
	case "386":
		shellcode, err = os.ReadFile(fmt.Sprintf("bin/x86/%s.bin", name))
	default:
		log.Fatalln("unsupported architecture:", runtime.GOARCH)
	}
	checkError(err)
	size := uintptr(len(shellcode))
	mType := uint32(windows.MEM_COMMIT | windows.MEM_RESERVE)
	mProtect := uint32(windows.PAGE_EXECUTE_READWRITE)
	scAddr, err := windows.VirtualAlloc(0, size, mType, mProtect)
	checkError(err)
	dst := unsafe.Slice((*byte)(unsafe.Pointer(scAddr)), size)
	copy(dst, shellcode)
	return scAddr
}

func calcHash(module, function string) (uintptr, uintptr) {
	var (
		hash []byte
		key  []byte
		err  error
	)
	switch runtime.GOARCH {
	case "amd64":
		hash, key, err = rorwk.Hash64(module, function)
	case "386":
		hash, key, err = rorwk.Hash32(module, function)
	default:
		log.Fatalln("unsupported architecture:", runtime.GOARCH)
	}
	checkError(err)
	h := uintptr(rorwk.BytesToUint64(hash))
	k := uintptr(rorwk.BytesToUint64(key))
	return h, k
}

func checkError(err error) {
	if err != nil {
		log.Fatalln(err)
	}
}
