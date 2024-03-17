package rorwk

import (
	"bytes"
	"fmt"
	"testing"

	"github.com/stretchr/testify/require"
)

func TestHash64(t *testing.T) {
	hash, key, err := Hash64("kernel32.dll", "CreateThread")
	require.NoError(t, err)
	require.Len(t, hash, 8)
	require.Len(t, key, 8)

	fmt.Println("hash:", hash)
	fmt.Println("key:", key)
}

func TestHash32(t *testing.T) {
	hash, key, err := Hash32("kernel32.dll", "CreateThread")
	require.NoError(t, err)
	require.Len(t, hash, 4)
	require.Len(t, key, 4)

	fmt.Println("hash:", hash)
	fmt.Println("key:", key)
}

func TestBytesToUintptr(t *testing.T) {
	val := BytesToUintptr(bytes.Repeat([]byte{0x11}, 8))
	require.Equal(t, uintptr(0x1111111111111111), val)

	val = BytesToUintptr(bytes.Repeat([]byte{0x11}, 4))
	require.Equal(t, uintptr(0x11111111), val)

	val = BytesToUintptr(bytes.Repeat([]byte{0x11}, 3))
	require.Zero(t, val)
	val = BytesToUintptr(bytes.Repeat([]byte{0x11}, 9))
	require.Zero(t, val)

	val = BytesToUintptr(nil)
	require.Zero(t, val)
}
