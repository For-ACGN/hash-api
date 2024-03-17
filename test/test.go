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
}

func testFindAPI() {
	shellcode := loadShellcode("find_api")
	size := uintptr(len(shellcode))
	mType := uint32(windows.MEM_COMMIT | windows.MEM_RESERVE)
	mProtect := uint32(windows.PAGE_EXECUTE_READWRITE)
	scAddr, err := windows.VirtualAlloc(0, size, mType, mProtect)
	checkError(err)
	dst := unsafe.Slice((*byte)(unsafe.Pointer(scAddr)), size)
	copy(dst, shellcode)

	hashData, keyData, err := rorwk.Hash64("kernel32.dll", "ReadProcessMemory")
	checkError(err)
	hash := rorwk.BytesToUintptr(hashData)
	key := rorwk.BytesToUintptr(keyData)
	apiAddr, _, err := syscall.SyscallN(scAddr, hash, key)
	fmt.Println(err)

	proc := windows.NewLazySystemDLL("kernel32.dll").NewProc("ReadProcessMemory").Addr()
	if proc != apiAddr {
		log.Fatalf("expected address: 0x%016X, actual: 0x%016X\n", proc, apiAddr)
	}

	hashData, keyData, err = rorwk.Hash64("invalid.dll", "ReadProcessMemory")
	checkError(err)
	hash = rorwk.BytesToUintptr(hashData)
	key = rorwk.BytesToUintptr(keyData)
	apiAddr, _, err = syscall.SyscallN(scAddr, hash, key)
	fmt.Println(err)
	if apiAddr != 0 {
		log.Fatalln("unexpected return value:", apiAddr)
	}

	hashData, keyData, err = rorwk.Hash64("kernel32.dll", "Invalid")
	checkError(err)
	hash = rorwk.BytesToUintptr(hashData)
	key = rorwk.BytesToUintptr(keyData)
	apiAddr, _, err = syscall.SyscallN(scAddr, hash, key)
	fmt.Println(err)
	if apiAddr != 0 {
		log.Fatalln("unexpected return value:", apiAddr)
	}
}

func testAPICall() {
	shellcode := loadShellcode("hash_api")
	size := uintptr(len(shellcode))
	mType := uint32(windows.MEM_COMMIT | windows.MEM_RESERVE)
	mProtect := uint32(windows.PAGE_EXECUTE_READWRITE)
	scAddr, err := windows.VirtualAlloc(0, size, mType, mProtect)
	checkError(err)
	dst := unsafe.Slice((*byte)(unsafe.Pointer(scAddr)), size)
	copy(dst, shellcode)

	hashData, keyData, err := rorwk.Hash64("kernel32.dll", "CreateThread")
	checkError(err)
	hash := rorwk.BytesToUintptr(hashData)
	key := rorwk.BytesToUintptr(keyData)
	var threadID uint32
	handle, _, err := syscall.SyscallN(
		scAddr, hash, key,
		0, 0, scAddr, 0, windows.CREATE_SUSPENDED,
		uintptr(unsafe.Pointer(&threadID)),
	)
	fmt.Println(err)

	err = windows.CloseHandle(windows.Handle(handle))
	if err != nil {
		log.Fatalln("failed to close thread handle:", err)
	}
	fmt.Println("thread id:", threadID)
}

func loadShellcode(name string) []byte {
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
	return shellcode
}

func checkError(err error) {
	if err != nil {
		log.Fatalln(err)
	}
}
