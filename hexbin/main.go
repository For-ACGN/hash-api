package main

import (
	"bytes"
	"encoding/hex"
	"fmt"
	"log"
	"os"
	"strings"
)

func main() {
	if len(os.Args) < 2 {
		log.Fatalln("must input file path")
	}
	data, err := os.ReadFile(os.Args[1])
	if err != nil {
		log.Fatalln(err)
	}
	fmt.Println(dumpBytesHex(data))
}

func dumpBytesHex(b []byte) string {
	n := len(b)
	builder := strings.Builder{}
	builder.Grow(len("0xFF, ")*n - len(", "))
	buf := make([]byte, 2)
	var counter = 0
	for i := 0; i < n; i++ {
		if counter == 0 {
			builder.WriteString("    ")
		}
		builder.WriteString("0x")
		hex.Encode(buf, b[i:i+1])
		builder.Write(bytes.ToUpper(buf))
		builder.WriteString(", ")
		counter++
		if counter != 16 {
			continue
		}
		builder.WriteString("\r\n")
		counter = 0
	}
	return builder.String()
}
