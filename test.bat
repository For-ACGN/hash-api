set GOOS=windows
set GOARCH=amd64
go run test/test.go
set GOARCH=386
go run test/test.go