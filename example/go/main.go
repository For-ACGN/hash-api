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
	findAPIAddr := loadShellcode("find_api")
	var (
		hash uint64 // "uintptr" for pass go build
		key  uint64 // "uintptr" for pass go build
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
	apiAddr, _, err := syscall.SyscallN(findAPIAddr, uintptr(hash), uintptr(key))
	fmt.Println(err)
	fmt.Printf("ReadProcessMemory: 0x%08X\n", apiAddr)
}

func apiCall() {
	testdata := []byte{0x11, 0x22, 0x33, 0x44}
	buf := make([]byte, 4)
	read := uint32(0)

	hProcess := uintptr(windows.CurrentProcess())
	address := uintptr(unsafe.Pointer(&testdata[0]))
	bufAddr := uintptr(unsafe.Pointer(&buf[0]))
	bufLen := uintptr(len(buf))
	numRead := uintptr(unsafe.Pointer(&read))

	apiCallAddr := loadShellcode("api_call")
	var (
		hash uint64 // "uintptr" for pass go build
		key  uint64 // "uintptr" for pass go build
	)
	switch runtime.GOARCH {
	case "amd64":
		hash = 0x19F0408D11729CE1
		key = 0x770BAC188977E15D
	case "386":
		hash = 0x57FA7605
		key = 0xA2DDED61
	default:
		log.Fatalln("unsupported architecture:", runtime.GOARCH)
	}
	ret, _, err := syscall.SyscallN(
		apiCallAddr, uintptr(hash), uintptr(key), 5,
		hProcess, address, bufAddr, bufLen, numRead,
	)
	fmt.Println(err)
	if ret == 0 {
		log.Fatalln("failed to read process memory")
	}
	fmt.Println(buf)
	fmt.Println(read)
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

func checkError(err error) {
	if err != nil {
		log.Fatalln(err)
	}
}
