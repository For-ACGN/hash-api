package main

import (
	"fmt"
	"log"
	"os"
	"runtime"
	"syscall"
	"unsafe"

	"golang.org/x/sys/windows"
)

func main() {
	findAPI()
	apiCall()
}

func findAPI() {
	var (
		hash uintptr
		key  uintptr
	)
	switch runtime.GOARCH {
	case "amd64":
		hash = 0xDE52F654501649E2
		key = 0x138EE92A21D8DC64
	case "386":
		hash = 0x923C05CD
		key = 0xA0AF83FD
	default:
		log.Fatalln("unsupported architecture:", runtime.GOARCH)
	}
	findAPIAddr := loadShellcode("find_api")
	apiAddr, _, err := syscall.SyscallN(findAPIAddr, hash, key)
	fmt.Println(err)
	fmt.Printf("ReadProcessMemory: 0x%08X\n", apiAddr)
}

func apiCall() {

}

func loadShellcode(name string) uintptr {
	var (
		shellcode []byte
		err       error
	)
	switch runtime.GOARCH {
	case "amd64":
		shellcode, err = os.ReadFile(fmt.Sprintf("../../bin/x64/%s.bin", name))
	case "386":
		shellcode, err = os.ReadFile(fmt.Sprintf("../../bin/x86/%s.bin", name))
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

func checkError(err error) {
	if err != nil {
		log.Fatalln(err)
	}
}
