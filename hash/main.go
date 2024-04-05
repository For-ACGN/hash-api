package main

import (
	"encoding/hex"
	"flag"
	"fmt"
	"log"
	"runtime"
	"strings"

	"github.com/For-ACGN/hash-api/rorwk"
)

var (
	format   string
	modName  string
	funcName string
)

func init() {
	var defaultFormat string
	switch runtime.GOARCH {
	case "386":
		defaultFormat = "32"
	case "amd64":
		defaultFormat = "64"
	}
	flag.StringVar(&format, "fmt", defaultFormat, "binary format: 32 or 64")
	flag.StringVar(&modName, "mod", "kernel32.dll", "module name")
	flag.StringVar(&funcName, "func", "WinExec", "function name")
	flag.Parse()
}

func main() {
	fmt.Println("module:  ", modName)
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
		apiHash, hashKey, err = rorwk.Hash32(modName, funcName)
		numZero = "8"
	case "64":
		apiHash, hashKey, err = rorwk.Hash64(modName, funcName)
		numZero = "16"
	default:
		log.Fatalln("invalid format:", format)
	}
	if err != nil {
		log.Fatalln("failed to calculate hash:", err)
	}
	fmt.Printf("Hash: 0x%0"+numZero+"X\n", rorwk.BytesToUint64(apiHash))
	fmt.Printf("Key:  0x%0"+numZero+"X\n", rorwk.BytesToUint64(hashKey))
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
