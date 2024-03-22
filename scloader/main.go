package main

import (
	"flag"
	"fmt"
	"log"
	"os"
	"syscall"
	"unsafe"

	"golang.org/x/sys/windows"
)

var scPath string

func init() {
	flag.StringVar(&scPath, "sc", "shellcode.bin", "shellcode file path")
	flag.Parse()
}

func main() {
	// read shellcode from file
	shellcode, err := os.ReadFile(scPath)
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
	fmt.Println("return value:", ret)
}

func checkError(err error) {
	if err != nil {
		log.Fatalln(err)
	}
}
