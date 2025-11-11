# 轻量级 Socks5 代理服务器

## 项目概述

这是一个基于 Bash 和 socat 的轻量级 Socks5 代理服务器实现，专注于简单部署和高效运行。适合在 Linux 服务器上快速搭建代理服务，无需复杂配置。

## 核心特性

- **智能 IP 检测**：自动识别并显示服务器公网或内网 IP 地址
- **一键式部署**：单命令完成所有安装和配置流程
- **标准端口配置**：默认使用 1080 端口，符合行业标准
- **优雅的安装体验**：平滑的彩色进度条，提供直观的安装反馈
- **智能防火墙配置**：自动检测并配置 ufw 或 iptables
- **系统服务集成**：通过 systemd 管理，支持开机自启
- **静默安装模式**：最小化命令输出，专注于核心信息展示
- **跨发行版兼容**：支持所有主流 Debian/Ubuntu 系统

## 快速开始

在 Debian/Ubuntu 系统上，只需执行以下命令即可完成安装：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Luv9-cn/socks5/master/install.sh)
```

### 安装过程

安装脚本将自动执行以下操作：
1. 更新系统包列表
2. 安装必要的依赖（socat, wget, curl）
3. 创建专用目录和服务脚本
4. 配置 systemd 服务
5. 设置防火墙规则
6. 显示完整的代理配置信息

## 代理配置

安装完成后，脚本会自动显示以下配置信息：

- **协议**: Socks5
- **地址**: socks5://[服务器IP]:1080
- **认证**: 无需认证
- **管理**: systemctl [start|stop|restart] socks5-proxy

## 客户端设置指南

### Windows

1. 打开控制面板 → 网络和 Internet → 互联网选项
2. 选择"连接"选项卡 → 局域网设置
3. 勾选"为 LAN 使用代理服务器"
4. 填写地址和端口，点击确定

### macOS

1. 打开系统偏好设置 → 网络 → 高级
2. 选择"代理"选项卡
3. 勾选"SOCKS 代理"，填写地址和端口
4. 点击确定并应用更改

### Linux

在终端中设置环境变量：
```bash
export http_proxy="socks5://[服务器IP]:1080"
export https_proxy="socks5://[服务器IP]:1080"
```

### 浏览器扩展

推荐使用 SwitchyOmega、FoxyProxy 等浏览器扩展进行更灵活的代理控制。

## 服务管理

- **启动服务**: `systemctl start socks5-proxy`
- **停止服务**: `systemctl stop socks5-proxy`
- **重启服务**: `systemctl restart socks5-proxy`
- **查看状态**: `systemctl status socks5-proxy`

## 技术架构

### 核心依赖

| 组件 | 版本 | 用途 |
|------|------|------|
| Bash | 4.0+ | 脚本运行环境 |
| socat | 1.7.0+ | TCP 端口转发 |
| wget | 1.20+ | 文件下载 |
| curl | 7.60+ | IP 检测 |
| systemd | 230+ | 服务管理 |
| ufw/iptables | - | 防火墙配置 |

### 工作原理

使用 socat 进行 TCP 端口转发，将本地 1080 端口的 Socks5 连接转发到目标服务，实现代理功能。所有配置均通过纯 Bash 脚本自动完成，无需手动干预。

## 性能与安全

- **低资源占用**: 内存占用通常低于 10MB
- **高并发支持**: 可处理数百个并发连接
- **安全考虑**: 建议在生产环境中配置防火墙限制访问来源

## 故障排查

### 常见问题

- **端口被占用**: 检查 1080 端口是否被其他服务占用
- **防火墙问题**: 手动检查防火墙规则是否正确配置
- **服务启动失败**: 查看日志 `journalctl -u socks5-proxy`

## 贡献指南

欢迎提交 Issue 和 Pull Request 来改进这个项目。

## 许可证

本项目采用 MIT 许可证开源 - 详情请查看 [LICENSE](LICENSE) 文件

## 联系与支持

- **作者**: Socks5 Team
- **项目地址**: [https://github.com/Luv9-cn/socks5](https://github.com/Luv9-cn/socks5)
- **反馈渠道**: GitHub Issues

