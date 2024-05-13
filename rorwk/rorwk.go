package rorwk

import (
	"crypto/rand"
	"crypto/sha256"
	"encoding/binary"
	"strings"
	"unicode"

	"github.com/pkg/errors"
)

// HashAPI64 is used to calculate Windows API hash for 64 bit.
func HashAPI64(module, function string) ([]byte, []byte, error) {
	key, err := generateKey()
	if err != nil {
		return nil, nil, err
	}
	key = key[:8]
	hash, err := HashAPI64WithKey(module, function, key)
	if err != nil {
		return nil, nil, err
	}
	return hash, key, nil
}

// HashAPI32 is used to calculate Windows API hash for 32 bit.
func HashAPI32(module, function string) ([]byte, []byte, error) {
	key, err := generateKey()
	if err != nil {
		return nil, nil, err
	}
	key = key[:4]
	hash, err := HashAPI32WithKey(module, function, key)
	if err != nil {
		return nil, nil, err
	}
	return hash, key, nil
}

// HashAPI64WithKey is used to calculate Windows API hash for 64 bit with specific key.
func HashAPI64WithKey(module, function string, key []byte) ([]byte, error) {
	if len(key) != 8 {
		return nil, errors.New("invalid hash api key size")
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
	seedHash = binary.LittleEndian.Uint64(key)
	for _, b := range key {
		seedHash = ror64(seedHash, rorSeed)
		seedHash += uint64(b)
	}
	keyHash = seedHash
	for _, b := range key {
		keyHash = ror64(keyHash, rorKey)
		keyHash += uint64(b)
	}
	moduleHash = seedHash
	if isASCII(module) {
		modName := toUnicode(module + "\x00")
		for _, c := range modName {
			moduleHash = ror64(moduleHash, rorMod)
			moduleHash += uint64(c)
		}
	} else {
		modName := []byte(module + "\x00\x00")
		for _, c := range modName {
			if c >= 'a' {
				c -= 0x20
			}
			moduleHash = ror64(moduleHash, rorMod)
			moduleHash += uint64(c)
		}
	}
	functionHash = seedHash
	for _, c := range function + "\x00" {
		functionHash = ror64(functionHash, rorFunc)
		functionHash += uint64(c)
	}
	apiHash := seedHash + keyHash + moduleHash + functionHash
	hash := make([]byte, 8)
	binary.LittleEndian.PutUint64(hash, apiHash)
	return hash, nil
}

// HashAPI32WithKey is used to calculate Windows API hash for 32 bit with specific key.
func HashAPI32WithKey(module, function string, key []byte) ([]byte, error) {
	if len(key) != 4 {
		return nil, errors.New("invalid hash api key size")
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
	seedHash = binary.LittleEndian.Uint32(key)
	for _, b := range key {
		seedHash = ror32(seedHash, rorSeed)
		seedHash += uint32(b)
	}
	keyHash = seedHash
	for _, b := range key {
		keyHash = ror32(keyHash, rorKey)
		keyHash += uint32(b)
	}
	moduleHash = seedHash
	if isASCII(module) {
		modName := toUnicode(module + "\x00")
		for _, c := range modName {
			moduleHash = ror32(moduleHash, rorMod)
			moduleHash += uint32(c)
		}
	} else {
		modName := []byte(module + "\x00\x00")
		for _, c := range modName {
			if c >= 'a' {
				c -= 0x20
			}
			moduleHash = ror32(moduleHash, rorMod)
			moduleHash += uint32(c)
		}
	}
	functionHash = seedHash
	for _, c := range function + "\x00" {
		functionHash = ror32(functionHash, rorFunc)
		functionHash += uint32(c)
	}
	apiHash := seedHash + keyHash + moduleHash + functionHash
	hash := make([]byte, 4)
	binary.LittleEndian.PutUint32(hash, apiHash)
	return hash, nil
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
	hash := sha256.Sum256(key)
	return hash[:], nil
}

func isASCII(s string) bool {
	for _, r := range s {
		if r > unicode.MaxASCII || r == 0x00 {
			return false
		}
	}
	return true
}

func toUnicode(s string) string {
	u := strings.Builder{}
	u.Grow(len(s) * 2)
	for _, r := range strings.ToUpper(s) {
		u.WriteRune(r)
		u.WriteByte(0x00)
	}
	return u.String()
}

func ror64(value, bits uint64) uint64 {
	return value>>bits | value<<(64-bits)
}

func ror32(value, bits uint32) uint32 {
	return value>>bits | value<<(32-bits)
}
