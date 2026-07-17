package proxy

import (
	"fmt"
	"log"
	"net"

	"github.com/armon/go-socks5"
)

// StartSOCKS5 启动SOCKS5代理服务器
func StartSOCKS5(port int, username, password string) error {
	conf := &socks5.Config{
		Logger: log.Default(),
	}

	if username != "" && password != "" {
		creds := socks5.StaticCredentials{
			username: password,
		}
		cator := socks5.UserPassAuthenticator{Credentials: creds}
		conf.AuthMethods = []socks5.Authenticator{cator}
		conf.Credentials = creds
		log.Printf("[SOCKS5] 已启用用户认证: %s", username)
	}

	server, err := socks5.New(conf)
	if err != nil {
		return fmt.Errorf("创建SOCKS5服务器失败: %w", err)
	}

	addr := fmt.Sprintf("0.0.0.0:%d", port)
	listener, err := net.Listen("tcp", addr)
	if err != nil {
		return fmt.Errorf("SOCKS5监听 %s 失败: %w", addr, err)
	}

	log.Printf("[SOCKS5] 代理已启动 -> %s", addr)
	return server.Serve(listener)
}