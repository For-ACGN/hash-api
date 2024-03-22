package rorwk

import (
	"bytes"
	"crypto/rand"
	"errors"
	"fmt"
	"testing"

	"github.com/For-ACGN/monkey"
	"github.com/stretchr/testify/require"
)

func TestHash64(t *testing.T) {
	t.Run("common", func(t *testing.T) {
		hash, key, err := Hash64("kernel32.dll", "CreateThread")
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

		hash, key, err := Hash64("kernel32.dll", "CreateThread")
		require.ErrorContains(t, err, "monkey error")
		require.Nil(t, hash)
		require.Nil(t, key)
	})
}

func TestHash32(t *testing.T) {
	t.Run("common", func(t *testing.T) {
		hash, key, err := Hash32("kernel32.dll", "CreateThread")
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

		hash, key, err := Hash32("kernel32.dll", "CreateThread")
		require.ErrorContains(t, err, "monkey error")
		require.Nil(t, hash)
		require.Nil(t, key)
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
