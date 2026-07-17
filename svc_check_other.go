//go:build !windows

package main

func svcIsService() (bool, error) {
	return false, nil
}

func runService(name string) {}