# 轻量级 Socks5 代理服务器

**作者:** Socks5 Team  
**开源地址:** [https://github.com/username/socks5](https://github.com/username/socks5)  
**许可证:** MIT

## 功能特性

- **自动IP识别**: 智能检测服务器公网或内网IP
- **一键安装**: 极简安装流程，静默配置
- **默认端口**: 使用标准1080端口
- **简洁美观输出**: 彩色进度条和清晰的配置信息展示
- **自动防火墙配置**: 智能检测并开放端口
- **服务持久化**: systemd管理，开机自启

## 安装方法

在Debian 12服务器上执行：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/username/socks5/master/install.sh)
```

安装过程将显示彩色进度条，直观展示安装进度。

## 代理配置

安装完成后，会显示以下代理服务器配置信息：

- **协议类型**：Socks5
- **完整地址**：socks5://[服务器IP]:1080
- **认证方式**：无需认证
- **管理命令**：systemctl [start|stop|restart] socks5

## 客户端配置

在客户端设备中配置：
- 代理类型: Socks5
- 服务器地址: [安装后显示的IP]
- 端口: 1080
- 认证: 无需认证

## 技术依赖

- Bash Shell
- socat, wget, curl
- systemd
- ufw/iptables (自动检测)

## 许可证

MIT
