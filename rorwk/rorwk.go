package rorwk

import (
	"crypto/sha256"
	"encoding/binary"
	"strings"

	"github.com/pkg/errors"
)

// Hash64 is used to calculate hash for 64 bit.
func Hash64(module, function string, key []byte) (uint64, []byte) {
	const bits = 8
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
	apiHash := seedHash + keyHash + moduleHash + functionHash
	return apiHash, hashKey
}

func ror64(value, bits uint64) uint64 {
	return value>>bits | value<<(64-bits)
}

// Hash32 is used to calculate hash for 32 bit.
func Hash32(module, function string, key []byte) (uint32, []byte) {
	const bits = 4
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
		seedHash = ror32(seedHash, bits+1)
		seedHash += uint32(b)
	}
	keyHash = seedHash
	for _, b := range hashKey {
		keyHash = ror32(keyHash, bits+2)
		keyHash += uint32(b)
	}
	moduleHash = seedHash
	for _, c := range toUnicode(module + "\x00") {
		moduleHash = ror32(moduleHash, bits+3)
		moduleHash += uint32(c)
	}
	functionHash = seedHash
	for _, c := range function + "\x00" {
		functionHash = ror32(functionHash, bits+4)
		functionHash += uint32(c)
	}
	apiHash := seedHash + keyHash + moduleHash + functionHash
	return apiHash, hashKey
}

func ror32(value, bits uint32) uint32 {
	return value>>bits | value<<(32-bits)
}

// KeyToUintptr is used to convert key bytes to uintptr
func KeyToUintptr(key []byte) (uintptr, error) {
	n := len(key)
	switch n {
	case 4:
		v := binary.LittleEndian.Uint32(key)
		return uintptr(v), nil
	case 8:
		v := binary.LittleEndian.Uint64(key)
		return uintptr(v), nil
	default:
		return 0, errors.Errorf("invalid key size: %d", n)
	}
}

func toUnicode(s string) string {
	var u string
	for _, c := range strings.ToUpper(s) {
		u += string(c) + "\x00"
	}
	return u
}
