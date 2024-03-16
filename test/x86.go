package main

func main() {

}

// hash := Hash("kernel32.dll", "LoadLibraryA", key)
//	fmt.Printf("hash: 0x%16X\n", hash)
//	hash = Hash("register.dll", "LoadDriver", key)
//	fmt.Printf("hash: 0x%16X\n", hash)
//
//	hash = Hash("kernel32.dll", "CreateThread", key)
//	fmt.Printf("hash: 0x%16X\n", hash)
//
//
//	hash = Hash("kernel322.dll", "ReadProcessMemory", key)
//	r1, _, err = syscall.SyscallN(addr, uintptr(hash), hashKey)
//	fmt.Println(err)
//	fmt.Println("func addr:     ", r1)
//
//	hash = Hash("kernel322.dll", "ReadProcessMemory1", key)
//	r1, _, err = syscall.SyscallN(addr, uintptr(hash), hashKey)
//	fmt.Println(err)
//	fmt.Println("func addr:     ", r1)
// 	r1, _, err := syscall.SyscallN(scAddr, hash, key,
//		0, 0, proc, 0,
//		windows.CREATE_SUSPENDED, ptr)
//	fmt.Println(err)
