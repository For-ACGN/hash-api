package main

import (
	"fmt"
	"log"
	"os"
	"syscall"
	"unsafe"

	"golang.org/x/sys/windows"
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
	memAddr, err := windows.VirtualAlloc(0, size, mType, mProtect)
	checkError(err)
	dst := unsafe.Slice((*byte)(unsafe.Pointer(memAddr)), size)
	copy(dst, shellcode)

	// hash -func LoadLibraryA
	hash := uintptr(0x3CD343F9C16EBCE7)
	key := uintptr(0x999B09FE522E0C84)
	addr, _, err := syscall.SyscallN(memAddr, hash, key)
	fmt.Println(err)

	proc := windows.NewLazySystemDLL("kernel32.dll").NewProc("LoadLibraryA").Addr()
	if proc == addr {
		return
	}
	log.Fatalf("expect address: 0x%016X, actual: 0x%016X\n", proc, addr)
}

func testAPICall() {
	shellcode, err := os.ReadFile("bin/x64/hash_api.bin")
	checkError(err)
	size := uintptr(len(shellcode))
	mType := uint32(windows.MEM_COMMIT | windows.MEM_RESERVE)
	mProtect := uint32(windows.PAGE_EXECUTE_READWRITE)
	memAddr, err := windows.VirtualAlloc(0, size, mType, mProtect)
	checkError(err)
	dst := unsafe.Slice((*byte)(unsafe.Pointer(memAddr)), size)
	copy(dst, shellcode)

	var threadID uint32
	tidPtr := uintptr(unsafe.Pointer(&threadID))

	// hash -func CreateThread
	hash := uintptr(0xC35EA5E214B1F707)
	key := uintptr(0xB711B4C5A049896F)
	handle, _, err := syscall.SyscallN(
		memAddr, hash, key,
		0, 0, memAddr, 0, windows.CREATE_SUSPENDED, tidPtr,
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
