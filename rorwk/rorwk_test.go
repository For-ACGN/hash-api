package rorwk

import (
	"bytes"
	"crypto/rand"
	"encoding/binary"
	"errors"
	"fmt"
	"testing"

	"github.com/For-ACGN/monkey"
	"github.com/stretchr/testify/require"
)

func TestHashAPI64(t *testing.T) {
	t.Run("common", func(t *testing.T) {
		hash, key, err := HashAPI64("kernel32.dll", "CreateThread")
		require.NoError(t, err)
		require.Len(t, hash, 8)
		require.Len(t, key, 8)

		fmt.Println("hash:", hash)
		fmt.Println("key:", key)
	})

	t.Run("failed to generate key", func(t *testing.T) {
		patch := func(b []byte) (n int, err error) {
			return 0, errors.New("monkey error")
		}
		pg := monkey.Patch(rand.Read, patch)
		defer pg.Unpatch()

		hash, key, err := HashAPI64("kernel32.dll", "CreateThread")
		require.ErrorContains(t, err, "monkey error")
		require.Nil(t, hash)
		require.Nil(t, key)
	})

	t.Run("invalid key size", func(t *testing.T) {
		patch := func(string, string, []byte) ([]byte, error) {
			return nil, errors.New("monkey error")
		}
		pg := monkey.Patch(HashAPI64WithKey, patch)
		defer pg.Unpatch()

		hash, key, err := HashAPI64("kernel32.dll", "CreateThread")
		require.ErrorContains(t, err, "monkey error")
		require.Nil(t, hash)
		require.Nil(t, key)
	})
}

func TestHashAPI32(t *testing.T) {
	t.Run("common", func(t *testing.T) {
		hash, key, err := HashAPI32("kernel32.dll", "CreateThread")
		require.NoError(t, err)
		require.Len(t, hash, 4)
		require.Len(t, key, 4)

		fmt.Println("hash:", hash)
		fmt.Println("key:", key)
	})

	t.Run("failed to generate key", func(t *testing.T) {
		patch := func(b []byte) (n int, err error) {
			return 0, errors.New("monkey error")
		}
		pg := monkey.Patch(rand.Read, patch)
		defer pg.Unpatch()

		hash, key, err := HashAPI32("kernel32.dll", "CreateThread")
		require.ErrorContains(t, err, "monkey error")
		require.Nil(t, hash)
		require.Nil(t, key)
	})

	t.Run("invalid key size", func(t *testing.T) {
		patch := func(string, string, []byte) ([]byte, error) {
			return nil, errors.New("monkey error")
		}
		pg := monkey.Patch(HashAPI32WithKey, patch)
		defer pg.Unpatch()

		hash, key, err := HashAPI32("kernel32.dll", "CreateThread")
		require.ErrorContains(t, err, "monkey error")
		require.Nil(t, hash)
		require.Nil(t, key)
	})
}

func TestHashAPI64WithKey(t *testing.T) {
	key := make([]byte, 8)
	binary.LittleEndian.PutUint64(key, 0x6C752CFACA603193)

	t.Run("module name-ASCII", func(t *testing.T) {
		hash, err := HashAPI64WithKey("kernel32.dll", "CreateThread", key)
		require.NoError(t, err)

		expected := uint64(0x2E1D2B4F2E3787DB)
		actual := binary.LittleEndian.Uint64(hash)
		require.Equal(t, expected, actual)
	})

	t.Run("module name-unicode", func(t *testing.T) {
		var modName string
		for _, r := range "kernel32.dll" {
			modName += string(r)
			modName += "\x00"
		}
		hash, err := HashAPI64WithKey(modName, "CreateThread", key)
		require.NoError(t, err)

		expected := uint64(0x2E1D2B4F2E3787DB)
		actual := binary.LittleEndian.Uint64(hash)
		require.Equal(t, expected, actual)
	})

	t.Run("invalid key size", func(t *testing.T) {
		hash, err := HashAPI64WithKey("kernel32.dll", "CreateThread", nil)
		require.EqualError(t, err, "invalid hash api key size")
		require.Nil(t, hash)
	})
}

func TestHashAPI32WithKey(t *testing.T) {
	key := make([]byte, 4)
	binary.LittleEndian.PutUint32(key, 0x1B09A7DE)

	t.Run("module name-ASCII", func(t *testing.T) {
		hash, err := HashAPI32WithKey("kernel32.dll", "CreateThread", key)
		require.NoError(t, err)

		expected := uint32(0xB088C622)
		actual := binary.LittleEndian.Uint32(hash)
		require.Equal(t, expected, actual)
	})

	t.Run("module name-unicode", func(t *testing.T) {
		var modName string
		for _, r := range "kernel32.dll" {
			modName += string(r)
			modName += "\x00"
		}
		hash, err := HashAPI32WithKey(modName, "CreateThread", key)
		require.NoError(t, err)

		expected := uint32(0xB088C622)
		actual := binary.LittleEndian.Uint32(hash)
		require.Equal(t, expected, actual)
	})

	t.Run("invalid key size", func(t *testing.T) {
		hash, err := HashAPI32WithKey("kernel32.dll", "CreateThread", nil)
		require.EqualError(t, err, "invalid hash api key size")
		require.Nil(t, hash)
	})
}

func TestBytesToUint64(t *testing.T) {
	t.Run("8 bytes", func(t *testing.T) {
		key := []byte{0x00}
		key = append(key, bytes.Repeat([]byte{0x11}, 6)...)
		key = append(key, 0x33)
		val := BytesToUint64(key)
		require.Equal(t, uint64(0x3311111111111100), val)
	})

	t.Run("4 bytes", func(t *testing.T) {
		key := []byte{0x00}
		key = append(key, bytes.Repeat([]byte{0x11}, 2)...)
		key = append(key, 0x33)
		val := BytesToUint64(key)
		require.Equal(t, uint64(0x33111100), val)
	})

	t.Run("invalid bytes length", func(t *testing.T) {
		val := BytesToUint64(bytes.Repeat([]byte{0x11}, 3))
		require.Zero(t, val)

		val = BytesToUint64(bytes.Repeat([]byte{0x11}, 9))
		require.Zero(t, val)

		val = BytesToUint64(nil)
		require.Zero(t, val)
	})
}
