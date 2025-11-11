#!/bin/bash

# 定义颜色（保留用于必要输出）
GREEN="\e[1;32m"
RED="\e[1;31m"
RESET="\e[0m"

# 极简进度显示函数
show_progress() {
    printf "\r${GREEN}安装中... %2d%%${RESET}" $1
}

# 自动识别服务器IP地址（静默模式）
get_server_ip() {
    # 尝试多种方法获取公网IP
    if command -v curl &> /dev/null; then
        PUBLIC_IP=$(curl -s ifconfig.me || curl -s icanhazip.com || curl -s ident.me)
        if [ ! -z "$PUBLIC_IP" ] && [[ "$PUBLIC_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            echo "$PUBLIC_IP"
            return 0
        fi
    fi
    
    # 尝试wget获取
    if command -v wget &> /dev/null; then
        PUBLIC_IP=$(wget -qO- ifconfig.me || wget -qO- icanhazip.com || wget -qO- ident.me)
        if [ ! -z "$PUBLIC_IP" ] && [[ "$PUBLIC_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            echo "$PUBLIC_IP"
            return 0
        fi
    fi
    
    # 查找默认网络接口的IP
    if command -v ip &> /dev/null; then
        DEFAULT_INTERFACE=$(ip route | grep default | awk '{print $5}')
        if [ ! -z "$DEFAULT_INTERFACE" ]; then
            INTERFACE_IP=$(ip addr show "$DEFAULT_INTERFACE" | grep -oP 'inet \K[0-9.]+')
            if [ ! -z "$INTERFACE_IP" ]; then
                echo "$INTERFACE_IP"
                return 0
            fi
        fi
    fi
    
    # 失败时返回通用占位符
    echo "your-server-ip"
}

# 检查是否以root用户运行
if [ "$(id -u)" != "0" ]; then
   echo -e "${RED}错误: 此脚本需要以root用户运行${RESET}"
   exit 1
fi

# 初始化进度
progress=0
show_progress $progress

# 设置变量
INSTALL_DIR="/opt/socks5"
SERVER_SCRIPT="socks5_light.sh"
SERVICE_NAME="socks5-proxy"
PORT=1080  # 默认使用1080端口
GITHUB_REPO="https://raw.githubusercontent.com/Luv9-cn/socks5/master"

# 获取服务器IP
SERVER_IP=$(get_server_ip)

# 更新系统包和安装必要工具
apt update -qq 2>/dev/null
progress=20
show_progress $progress
apt install -y -qq socat wget curl 2>/dev/null
progress=40
show_progress $progress

# 创建安装目录并下载脚本
mkdir -p $INSTALL_DIR

# 尝试下载脚本
if ! wget -q -O "$INSTALL_DIR/$SERVER_SCRIPT" "$GITHUB_REPO/$SERVER_SCRIPT"; then
    # 失败时创建临时脚本文件
    cat > "$INSTALL_DIR/$SERVER_SCRIPT" << 'EOF'
#!/bin/bash

# 简易Socks5代理服务器脚本
PORT=1080

echo "Starting Socks5 proxy on port $PORT..."
socat TCP4-LISTEN:$PORT,reuseaddr,fork PROXY:127.0.0.1:0.0.0.0:0,proxyport=$PORT
EOF
fi

chmod +x "$INSTALL_DIR/$SERVER_SCRIPT"
progress=60
show_progress $progress

# 创建systemd服务文件
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
StandardOutput=null
StandardError=null

[Install]
WantedBy=multi-user.target
EOF

# 重新加载systemd配置和启动服务
systemctl daemon-reload > /dev/null 2>&1
systemctl enable $SERVICE_NAME > /dev/null 2>&1
systemctl start $SERVICE_NAME > /dev/null 2>&1
progress=85
show_progress $progress

# 自动配置防火墙（静默）
if command -v ufw &> /dev/null && ufw status | grep -q "Status: active"; then
    ufw allow $PORT/tcp > /dev/null 2>&1
elif command -v iptables &> /dev/null; then
    iptables -A INPUT -p tcp --dport $PORT -j ACCEPT > /dev/null 2>&1
    # 尝试保存iptables规则
    (command -v netfilter-persistent &> /dev/null && netfilter-persistent save) > /dev/null 2>&1
fi

progress=100
show_progress $progress

# 新行结束进度条
echo

# 获取服务器IP
SERVER_IP=$(get_server_ip)

# 显示最小化安装完成信息
echo -e "${GREEN}✓ 安装完成${RESET}"
echo -e "代理地址: socks5://${SERVER_IP}:${PORT}"
echo -e "服务命令: systemctl [start|stop|restart] ${SERVICE_NAME}"
