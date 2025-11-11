#!/bin/bash

# 轻量级Socks5代理服务器一键安装脚本 (Debian 12)
echo "========================================"
echo "轻量级Socks5代理服务器一键安装脚本"
echo "适用于 Debian 12 (快速安装版)"
echo "========================================"

# 检查是否以root用户运行
if [ "$(id -u)" != "0" ]; then
   echo "错误: 此脚本需要以root用户运行"
   exit 1
fi

# 设置变量
INSTALL_DIR="/opt/socks5"
SERVER_SCRIPT="socks5_light.sh"
SERVICE_NAME="socks5-proxy"
DEFAULT_PORT=1080
GITHUB_REPO="https://raw.githubusercontent.com/username/socks5/master"

# 提示用户输入端口
echo "请输入Socks5代理服务器端口号 (默认: $DEFAULT_PORT):"
read -p "端口号: " PORT
PORT=${PORT:-$DEFAULT_PORT}

# 最小化更新系统包，仅更新已安装包的索引而不升级所有包
echo "更新软件包索引..."
apt update -qq

# 安装必要工具，使用socat作为轻量级替代方案
echo "安装必要工具..."
apt install -y -qq socat wget

# 创建安装目录
echo "创建安装目录: $INSTALL_DIR"
mkdir -p $INSTALL_DIR

# 从GitHub下载轻量级服务器脚本
echo "获取Socks5服务器脚本..."
# 尝试下载脚本，添加重试机制
MAX_RETRIES=3
retry_count=0
download_success=false

while [ $retry_count -lt $MAX_RETRIES ]; do
    retry_count=$((retry_count + 1))
    echo "尝试下载 (尝试 $retry_count/$MAX_RETRIES)..."
    
    if wget -q -O "$INSTALL_DIR/$SERVER_SCRIPT" "$GITHUB_REPO/$SERVER_SCRIPT"; then
        echo "下载成功！"
        download_success=true
        break
    else
        echo "下载失败，正在重试..."
        sleep 2  # 等待2秒后重试
    fi
done

# 如果下载失败，显示指定提示
if [ "$download_success" = false ]; then
    echo "GitHub无法连接疑似作者跑路了"
    exit 1
fi

# 验证下载的文件是否有效
if [ ! -s "$INSTALL_DIR/$SERVER_SCRIPT" ]; then
    echo "GitHub无法连接疑似作者跑路了"
    exit 1
fi

# 设置执行权限
chmod +x $INSTALL_DIR/$SERVER_SCRIPT

# 创建systemd服务文件
echo "创建systemd服务..."
cat > /etc/systemd/system/$SERVICE_NAME.service << EOF
[Unit]
Description=Lightweight Socks5 Proxy Server
After=network.target

[Service]
Type=simple
WorkingDirectory=$INSTALL_DIR
ExecStart=/bin/bash $INSTALL_DIR/$SERVER_SCRIPT -p $PORT
Restart=on-failure
RestartSec=2
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=socks5-proxy

[Install]
WantedBy=multi-user.target
EOF

# 重新加载systemd配置
echo "重新加载systemd配置..."
systemctl daemon-reload

# 启用并启动服务
echo "启用并启动Socks5代理服务..."
systemctl enable $SERVICE_NAME
systemctl start $SERVICE_NAME

# 检查服务状态
echo "检查服务状态..."
systemctl status $SERVICE_NAME --no-pager

# 显示防火墙配置提示
echo ""
echo "========================================"
echo "Socks5代理服务器安装完成!"
echo "========================================"
echo "服务名称: $SERVICE_NAME"
echo "监听端口: $PORT"
echo "配置文件: $INSTALL_DIR/$SERVER_SCRIPT"
echo "服务文件: /etc/systemd/system/$SERVICE_NAME.service"
echo ""
echo "服务管理命令:"
echo "  启动服务: systemctl start $SERVICE_NAME"
echo "  停止服务: systemctl stop $SERVICE_NAME"
echo "  重启服务: systemctl restart $SERVICE_NAME"
echo "  查看状态: systemctl status $SERVICE_NAME"
echo "  查看日志: journalctl -u $SERVICE_NAME -f"
echo ""
echo "如果您的系统启用了防火墙，请确保允许端口 $PORT 的流量通过。"
echo "例如: ufw allow $PORT/tcp"
echo ""
echo "Socks5代理地址: socks5://您的服务器IP:$PORT"
echo "========================================"
