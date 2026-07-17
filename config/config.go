package config

import (
	"fmt"
	"os"
	"path/filepath"

	"gopkg.in/yaml.v3"
)

// Config 代理配置
type Config struct {
	LogEnabled bool         `yaml:"log_enabled"`
	HTTP       HTTPConfig   `yaml:"http"`
	SOCKS5     SOCKS5Config `yaml:"socks5"`
}

// HTTPConfig HTTP代理配置
type HTTPConfig struct {
	Enabled  bool   `yaml:"enabled"`
	Port     int    `yaml:"port"`
	Username string `yaml:"username"`
	Password string `yaml:"password"`
}

// SOCKS5Config SOCKS5代理配置
type SOCKS5Config struct {
	Enabled  bool   `yaml:"enabled"`
	Port     int    `yaml:"port"`
	Username string `yaml:"username"`
	Password string `yaml:"password"`
}

// DefaultConfig 返回默认配置
func DefaultConfig() *Config {
	return &Config{
		HTTP: HTTPConfig{
			Enabled:  true,
			Port:     8080,
			Username: "",
			Password: "",
		},
		SOCKS5: SOCKS5Config{
			Enabled:  true,
			Port:     1080,
			Username: "",
			Password: "",
		},
	}
}

// LoadConfig 从文件加载配置，如文件不存在则创建默认配置
func LoadConfig(path string) (*Config, error) {
	if path == "" {
		exe, err := os.Executable()
		if err != nil {
			exe = "."
		}
		path = filepath.Join(filepath.Dir(exe), "config.yaml")
	}

	data, err := os.ReadFile(path)
	if err != nil {
		if os.IsNotExist(err) {
			cfg := DefaultConfig()
			if saveErr := SaveConfig(path, cfg); saveErr != nil {
				return nil, fmt.Errorf("创建默认配置文件失败: %w", saveErr)
			}
			return cfg, nil
		}
		return nil, fmt.Errorf("读取配置文件失败: %w", err)
	}

	cfg := DefaultConfig()
	if err := yaml.Unmarshal(data, cfg); err != nil {
		return nil, fmt.Errorf("解析配置文件失败: %w", err)
	}

	return cfg, nil
}

// SaveConfig 保存配置到文件
func SaveConfig(path string, cfg *Config) error {
	data, err := yaml.Marshal(cfg)
	if err != nil {
		return fmt.Errorf("序列化配置失败: %w", err)
	}
	return os.WriteFile(path, data, 0644)
}