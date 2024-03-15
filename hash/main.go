package main

import (
	"crypto/sha256"
	"encoding/binary"
	"encoding/hex"
	"flag"
	"fmt"
	"log"
	"strings"
)

var (
	format   string
	modName  string
	funcName string
	key      string
)

func init() {
	flag.StringVar(&format, "fmt", "64", "binary format: 32 or 64")
	flag.StringVar(&modName, "mod", "kernel32.dll", "dll name")
	flag.StringVar(&funcName, "func", "WinExec", "function name")
	flag.StringVar(&key, "key", "test_key", "hash key")
	flag.Parse()
}

func main() {
	fmt.Println("module:  ", modName)
	fmt.Println("function:", funcName)
	fmt.Printf("format:   %sbit\n", format)
	fmt.Println()
	switch format {
	case "32":

	case "64":
		apiHash, hashKey := hash64(modName, funcName, key)
		fmt.Printf("Hash: 0x%016X\n", apiHash)
		fmt.Printf("Key:  %s\n", dumpHex(hashKey))
	default:
		log.Fatalln("invalid format")
	}
}

func hash64(module, function, key string) (uint64, []byte) {
	const bits = 8
	var (
		seedHash     uint64
		keyHash      uint64
		moduleHash   uint64
		functionHash uint64
	)
	hash := sha256.Sum256([]byte(key))
	hashKey := hash[:8]
	seedHash = binary.LittleEndian.Uint64(hashKey)
	for _, b := range hashKey {
		seedHash = ror64(seedHash, bits+1)
		seedHash += uint64(b)
	}
	keyHash = seedHash
	for _, b := range hashKey {
		keyHash = ror64(keyHash, bits+2)
		keyHash += uint64(b)
	}
	moduleHash = seedHash
	for _, c := range toUnicode(module + "\x00") {
		moduleHash = ror64(moduleHash, bits+3)
		moduleHash += uint64(c)
	}
	functionHash = seedHash
	for _, c := range function + "\x00" {
		functionHash = ror64(functionHash, bits+4)
		functionHash += uint64(c)
	}
	api := seedHash + keyHash + moduleHash + functionHash
	return api, hashKey
}

func ror64(value, bits uint64) uint64 {
	return value>>bits | value<<(64-bits)
}

func toUnicode(s string) string {
	var u string
	for _, c := range strings.ToUpper(s) {
		u += string(c) + "\x00"
	}
	return u
}

func dumpHex(b []byte) string {
	n := len(b)
	builder := strings.Builder{}
	builder.Grow(6*n - 2)
	for i := 0; i < n; i++ {
		builder.WriteString("0x")
		v := hex.EncodeToString([]byte{b[i]})
		v = strings.ToUpper(v)
		builder.WriteString(v)
		if i == n-1 {
			break
		}
		builder.WriteString(", ")
	}
	return builder.String()
}
