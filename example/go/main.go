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
		mHash uint64
		pHash uint64
		hKey  uint64
	)
	switch runtime.GOARCH {
	case "amd64":
		mHash = 0x80D454CDC1D9BDAA
		pHash = 0x56A481363379A27B
		hKey = 0xFE89D785432B338E
	case "386":
		mHash = 0xE5EDA5C0
		pHash = 0x2166B892
		hKey = 0x170B3C7F
	default:
		log.Fatalln("unsupported architecture:", runtime.GOARCH)
	}
	apiAddr, _, err := syscall.SyscallN(
		findAPIAddr, uintptr(mHash), uintptr(pHash), uintptr(hKey),
	)
	fmt.Println(err)
	fmt.Printf("ReadProcessMemory: 0x%08X\n", apiAddr)
}

func apiCall() {
	testdata := []byte{11, 22, 33, 44}
	buf := make([]byte, 4)
	read := uint32(0)

	hProcess := uintptr(windows.CurrentProcess())
	address := uintptr(unsafe.Pointer(&testdata[0]))
	bufAddr := uintptr(unsafe.Pointer(&buf[0]))
	bufLen := uintptr(len(buf))
	numRead := uintptr(unsafe.Pointer(&read))

	apiCallAddr := loadShellcode("api_call")
	var (
		mHash uint64
		pHash uint64
		hKey  uint64
	)
	switch runtime.GOARCH {
	case "amd64":
		mHash = 0x80D454CDC1D9BDAA
		pHash = 0x56A481363379A27B
		hKey = 0xFE89D785432B338E
	case "386":
		mHash = 0xE5EDA5C0
		pHash = 0x2166B892
		hKey = 0x170B3C7F
	default:
		log.Fatalln("unsupported architecture:", runtime.GOARCH)
	}
	ret, _, err := syscall.SyscallN(
		apiCallAddr, uintptr(mHash), uintptr(pHash), uintptr(hKey), 5,
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
