package main

import (
	"fmt"
	"log"
	"os"
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
	shellcode, err := os.ReadFile("bin/x64/find_api.bin")
	checkError(err)
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
	shellcode, err := os.ReadFile("bin/x64/hash_api.bin")
	checkError(err)
	size := uintptr(len(shellcode))
	mType := uint32(windows.MEM_COMMIT | windows.MEM_RESERVE)
	mProtect := uint32(windows.PAGE_EXECUTE_READWRITE)
	scAddr, err := windows.VirtualAlloc(0, size, mType, mProtect)
	checkError(err)
	dst := unsafe.Slice((*byte)(unsafe.Pointer(scAddr)), size)
	copy(dst, shellcode)

	var threadID uint32
	tidPtr := uintptr(unsafe.Pointer(&threadID))

	hashData, keyData, err := rorwk.Hash64("kernel32.dll", "CreateThread")
	checkError(err)
	hash := rorwk.BytesToUintptr(hashData)
	key := rorwk.BytesToUintptr(keyData)
	handle, _, err := syscall.SyscallN(
		scAddr, hash, key,
		0, 0, scAddr, 0, windows.CREATE_SUSPENDED, tidPtr,
	)
	fmt.Println(err)

	err = windows.CloseHandle(windows.Handle(handle))
	if err != nil {
		log.Fatalln("failed to close thread handle:", err)
	}
	fmt.Println("thread id:", threadID)
}

func checkError(err error) {
	if err != nil {
		log.Fatalln(err)
	}
}
