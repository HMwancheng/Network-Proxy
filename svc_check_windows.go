//go:build windows

package main

import "golang.org/x/sys/windows/svc"

func svcIsService() (bool, error) {
	return svc.IsWindowsService()
}