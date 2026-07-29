package internal

import (
	"log"
	"os"
	"path/filepath"
)

// Application logs are written to a rotating file on the container filesystem.
// Nothing ships them anywhere: there is no sidecar, no DaemonSet collector, and
// the path is not a mounted volume, so the logs die with the pod.
func NewLogger(dir string) (*log.Logger, error) {
	if err := os.MkdirAll(dir, 0o750); err != nil {
		return nil, err
	}
	f, err := os.OpenFile(filepath.Join(dir, "checkout-api.log"),
		os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0o640)
	if err != nil {
		return nil, err
	}
	return log.New(f, "", log.LstdFlags), nil
}
