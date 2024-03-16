package main

import (
	"encoding/hex"
	"flag"
	"fmt"
	"log"
	"strings"

	"github.com/For-ACGN/hash-api/rorwk"
)

var (
	format   string
	dllName  string
	funcName string
)

func init() {
	flag.StringVar(&format, "fmt", "64", "binary format: 32 or 64")
	flag.StringVar(&dllName, "mod", "kernel32.dll", "module name")
	flag.StringVar(&funcName, "func", "WinExec", "function name")
	flag.Parse()
}

func main() {
	fmt.Println("module:  ", dllName)
	fmt.Println("function:", funcName)
	fmt.Printf("format:   %s bit\n", format)
	fmt.Println()
	var (
		numZero string
		apiHash []byte
		hashKey []byte
		err     error
	)
	switch format {
	case "32":
		apiHash, hashKey, err = rorwk.Hash32(dllName, funcName)
		numZero = "8"
	case "64":
		apiHash, hashKey, err = rorwk.Hash64(dllName, funcName)
		numZero = "16"
	default:
		log.Fatalln("invalid format:", format)
	}
	if err != nil {
		log.Fatalln("failed to calculate hash:", err)
	}
	fmt.Printf("Hash: 0x%0"+numZero+"X\n", rorwk.BytesToUintptr(apiHash))
	fmt.Printf("Key:  0x%0"+numZero+"X\n", rorwk.BytesToUintptr(hashKey))
	fmt.Printf("Hash: %s\n", dumpBytesHex(apiHash))
	fmt.Printf("Key:  %s\n", dumpBytesHex(hashKey))
}

func dumpBytesHex(b []byte) string {
	n := len(b)
	builder := strings.Builder{}
	builder.Grow(len("0xFF, ")*n - len(", "))
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
