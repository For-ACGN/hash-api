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
	if len(os.Args) < 2 {
		log.Fatalln("must input shellcode file path")
	}

	// read shellcode from file
	shellcode, err := os.ReadFile(os.Args[1])
	checkError(err)

	// allocate RWX memory for shellcode
	size := uintptr(len(shellcode))
	mType := uint32(windows.MEM_COMMIT | windows.MEM_RESERVE)
	mProtect := uint32(windows.PAGE_EXECUTE_READWRITE)
	scAddr, err := windows.VirtualAlloc(0, size, mType, mProtect)
	checkError(err)

	// write shellcode to RWX memory
	dst := unsafe.Slice((*byte)(unsafe.Pointer(scAddr)), size)
	copy(dst, shellcode)

	// call shellcode entry
	ret, _, err := syscall.SyscallN(scAddr)
	fmt.Println(err)
	fmt.Printf("return value: 0x%X %d\n", ret, ret)

	// exit and set exit code
	os.Exit(int(ret))
}

func checkError(err error) {
	if err != nil {
		log.Fatalln(err)
	}
}
