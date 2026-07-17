package main

import (
	"log"
	"os"
	"os/signal"

	"network-proxy/config"
	"network-proxy/proxy"
)

func main() {
	log.SetFlags(log.LstdFlags | log.Lshortfile)
	log.Println("[Main] Network Proxy 启动中...")

	cfg, err := config.LoadConfig("")
	if err != nil {
		log.Fatalf("[Main] 加载配置失败: %v", err)
	}

	// Windows服务模式
	isService, err := svcIsService()
	if err != nil {
		log.Fatalf("[Main] 检测服务状态失败: %v", err)
	}
	if isService {
		runService("NetworkProxy")
		return
	}

	// 控制台模式
	runProxyWithSignal(cfg)
}

func runProxy() {
	cfg, err := config.LoadConfig("")
	if err != nil {
		log.Fatalf("[Main] 加载配置失败: %v", err)
	}
	runProxyWithSignal(cfg)
}

func runProxyWithSignal(cfg *config.Config) {
	// 启动HTTP代理
	if cfg.HTTP.Enabled {
		go func() {
			if err := proxy.StartHTTP(cfg.HTTP.Port, cfg.HTTP.Username, cfg.HTTP.Password); err != nil {
				log.Printf("[Main] HTTP代理异常: %v", err)
			}
		}()
	} else {
		log.Println("[Main] HTTP代理已禁用")
	}

	// 启动SOCKS5代理
	if cfg.SOCKS5.Enabled {
		go func() {
			if err := proxy.StartSOCKS5(cfg.SOCKS5.Port, cfg.SOCKS5.Username, cfg.SOCKS5.Password); err != nil {
				log.Printf("[Main] SOCKS5代理异常: %v", err)
			}
		}()
	} else {
		log.Println("[Main] SOCKS5代理已禁用")
	}

	log.Println("[Main] 所有代理已启动，按 Ctrl+C 退出")

	// 等待退出信号
	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, os.Interrupt)
	<-sigCh
	log.Println("[Main] 正在退出...")
}