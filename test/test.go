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
	mHash, pHash, hKey := calcHash("kernel32.dll", "ReadProcessMemory")
	fmt.Printf("Module Hash:    0x%08X\n", mHash)
	fmt.Printf("Procedure Hash: 0x%08X\n", pHash)
	fmt.Printf("Hash Key:       0x%08X\n", hKey)

	apiAddr, _, err := syscall.SyscallN(findAPI, mHash, pHash, hKey)
	fmt.Println(err)
	proc := windows.NewLazySystemDLL("kernel32.dll").NewProc("ReadProcessMemory").Addr()
	if proc != apiAddr {
		log.Fatalf("expected address: 0x%08X, actual: 0x%08X\n", proc, apiAddr)
	}

	// api not found
	mHash, pHash, hKey = calcHash("invalid.dll", "ReadProcessMemory")
	apiAddr, _, err = syscall.SyscallN(findAPI, mHash, pHash, hKey)
	fmt.Println(err)
	if apiAddr != 0 {
		log.Fatalln("unexpected return value:", apiAddr)
	}

	mHash, pHash, hKey = calcHash("kernel32.dll", "Invalid")
	apiAddr, _, err = syscall.SyscallN(findAPI, mHash, pHash, hKey)
	fmt.Println(err)
	if apiAddr != 0 {
		log.Fatalln("unexpected return value:", apiAddr)
	}
}

func testAPICall() {
	apiCall := loadShellcode("api_call")
	mHash, pHash, hKey := calcHash("kernel32.dll", "CreateThread")
	fmt.Printf("Module Hash:    0x%08X\n", mHash)
	fmt.Printf("Procedure Hash: 0x%08X\n", pHash)
	fmt.Printf("Hash Key:       0x%08X\n", hKey)

	var threadID uint32
	handle, _, err := syscall.SyscallN(
		apiCall, mHash, pHash, hKey, 6,
		0, 0, apiCall, 0, windows.CREATE_SUSPENDED,
		uintptr(unsafe.Pointer(&threadID)),
	)
	fmt.Println(err)
	fmt.Printf("handle: 0x%08X\n", handle)

	e := windows.CloseHandle(windows.Handle(handle))
	if e != nil {
		log.Fatalln("failed to close thread handle:", err)
	}
	if threadID == 0 {
		log.Fatalln("unexpected thread id")
	}
	fmt.Println("thread id:", threadID)

	// api not found
	mHash, pHash, hKey = calcHash("invalid.dll", "ReadProcessMemory")
	ret, _, err := syscall.SyscallN(
		apiCall, mHash, pHash, hKey, 5,
		0, 0, 0, 0, 0,
	)
	fmt.Println(err)
	if ret != 0 {
		log.Fatalln("unexpected return value:", ret)
	}

	mHash, pHash, hKey = calcHash("kernel32.dll", "Invalid")
	ret, _, err = syscall.SyscallN(
		apiCall, mHash, pHash, hKey, 5,
		0, 0, 0, 0, 0,
	)
	fmt.Println(err)
	if ret != 0 {
		log.Fatalln("unexpected return value:", ret)
	}
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

func calcHash(module, function string) (uintptr, uintptr, uintptr) {
	var (
		mHash []byte
		pHash []byte
		hKey  []byte
		err   error
	)
	switch runtime.GOARCH {
	case "amd64":
		mHash, pHash, hKey, err = rorwk.HashAPI64(module, function)
	case "386":
		mHash, pHash, hKey, err = rorwk.HashAPI32(module, function)
	default:
		log.Fatalln("unsupported architecture:", runtime.GOARCH)
	}
	checkError(err)
	m := uintptr(rorwk.BytesToUint64(mHash))
	p := uintptr(rorwk.BytesToUint64(pHash))
	k := uintptr(rorwk.BytesToUint64(hKey))
	return m, p, k
}

func checkError(err error) {
	if err != nil {
		log.Fatalln(err)
	}
}
