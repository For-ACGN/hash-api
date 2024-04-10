package rorwk

import (
	"crypto/rand"
	"crypto/sha256"
	"encoding/binary"
	"strings"

	"github.com/pkg/errors"
)

// Hash64 is used to calculate hash for 64 bit.
func Hash64(module, function string) ([]byte, []byte, error) {
	key, err := generateKey()
	if err != nil {
		return nil, nil, err
	}
	const (
		rorBits = 8
		rorSeed = rorBits + 1
		rorKey  = rorBits + 2
		rorMod  = rorBits + 3
		rorFunc = rorBits + 4
	)
	var (
		seedHash     uint64
		keyHash      uint64
		moduleHash   uint64
		functionHash uint64
	)
	hash := sha256.Sum256(key)
	hashKey := hash[:8]
	seedHash = binary.LittleEndian.Uint64(hashKey)
	for _, b := range hashKey {
		seedHash = ror64(seedHash, rorSeed)
		seedHash += uint64(b)
	}
	keyHash = seedHash
	for _, b := range hashKey {
		keyHash = ror64(keyHash, rorKey)
		keyHash += uint64(b)
	}
	moduleHash = seedHash
	for _, c := range toUnicode(module + "\x00") {
		moduleHash = ror64(moduleHash, rorMod)
		moduleHash += uint64(c)
	}
	functionHash = seedHash
	for _, c := range function + "\x00" {
		functionHash = ror64(functionHash, rorFunc)
		functionHash += uint64(c)
	}
	apiHash := seedHash + keyHash + moduleHash + functionHash
	buf := make([]byte, 8)
	binary.LittleEndian.PutUint64(buf, apiHash)
	return buf, hashKey, nil
}

// Hash32 is used to calculate hash for 32 bit.
func Hash32(module, function string) ([]byte, []byte, error) {
	key, err := generateKey()
	if err != nil {
		return nil, nil, err
	}
	const (
		rorBits = 4
		rorSeed = rorBits + 1
		rorKey  = rorBits + 2
		rorMod  = rorBits + 3
		rorFunc = rorBits + 4
	)
	var (
		seedHash     uint32
		keyHash      uint32
		moduleHash   uint32
		functionHash uint32
	)
	hash := sha256.Sum256(key)
	hashKey := hash[:4]
	seedHash = binary.LittleEndian.Uint32(hashKey)
	for _, b := range hashKey {
		seedHash = ror32(seedHash, rorSeed)
		seedHash += uint32(b)
	}
	keyHash = seedHash
	for _, b := range hashKey {
		keyHash = ror32(keyHash, rorKey)
		keyHash += uint32(b)
	}
	moduleHash = seedHash
	for _, c := range toUnicode(module + "\x00") {
		moduleHash = ror32(moduleHash, rorMod)
		moduleHash += uint32(c)
	}
	functionHash = seedHash
	for _, c := range function + "\x00" {
		functionHash = ror32(functionHash, rorFunc)
		functionHash += uint32(c)
	}
	apiHash := seedHash + keyHash + moduleHash + functionHash
	buf := make([]byte, 4)
	binary.LittleEndian.PutUint32(buf, apiHash)
	return buf, hashKey, nil
}

// BytesToUint64 is used to convert hash or key bytes to uint64.
// It used to convert result to arguments for syscall.SyscallN.
func BytesToUint64(b []byte) uint64 {
	var val uint64
	switch len(b) {
	case 4:
		val = uint64(binary.LittleEndian.Uint32(b))
	case 8:
		val = binary.LittleEndian.Uint64(b)
	}
	return val
}

func generateKey() ([]byte, error) {
	key := make([]byte, 16)
	_, err := rand.Read(key)
	if err != nil {
		return nil, errors.Wrap(err, "failed to generate random key")
	}
	return key, nil
}

func ror64(value, bits uint64) uint64 {
	return value>>bits | value<<(64-bits)
}

func ror32(value, bits uint32) uint32 {
	return value>>bits | value<<(32-bits)
}

func toUnicode(s string) string {
	var u string
	for _, c := range strings.ToUpper(s) {
		u += string(c) + "\x00"
	}
	return u
}
