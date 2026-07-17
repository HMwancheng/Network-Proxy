//go:build windows

package main

import (
	"log"
	"os"
	"sync"
	"time"

	"golang.org/x/sys/windows/svc"
)

type proxyService struct {
	stopCh chan struct{}
	wg     sync.WaitGroup
}

func (s *proxyService) Execute(args []string, r <-chan svc.ChangeRequest, status chan<- svc.Status) (bool, uint32) {
	const cmdsAccepted = svc.AcceptStop | svc.AcceptShutdown
	status <- svc.Status{State: svc.StartPending}

	s.stopCh = make(chan struct{})

	// 启动代理
	go func() {
		runProxy()
	}()

	status <- svc.Status{State: svc.Running, Accepts: cmdsAccepted}
	log.Println("[Service] 服务已启动")

loop:
	for {
		select {
		case c := <-r:
			switch c.Cmd {
			case svc.Interrogate:
				status <- c.CurrentStatus
			case svc.Stop, svc.Shutdown:
				log.Println("[Service] 正在停止服务...")
				close(s.stopCh)
				time.Sleep(2 * time.Second)
				break loop
			default:
				log.Printf("[Service] 未知命令: %d", c.Cmd)
			}
		}
	}

	status <- svc.Status{State: svc.StopPending}
	return false, 0
}

func runService(name string) {
	err := svc.Run(name, &proxyService{})
	if err != nil {
		log.Printf("[Service] 服务启动失败: %v", err)
		os.Exit(1)
	}
}