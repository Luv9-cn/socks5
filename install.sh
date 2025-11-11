#!/bin/bash

# 定义颜色
GREEN="\e[1;32m"
BLUE="\e[1;34m"
YELLOW="\e[1;33m"
RED="\e[1;31m"
CYAN="\e[1;36m"
RESET="\e[0m"

# 轻量级Socks5代理服务器一键安装脚本
echo -e "${CYAN}────────────────────────────────────────${RESET}"
echo -e "${BLUE}     轻量级 Socks5 代理服务器${RESET}"
echo -e "${CYAN}────────────────────────────────────────${RESET}"

# 进度条函数 - 更简约的设计
show_progress() {
    local width=40
    local percentage=$1
    local filled=$((percentage * width / 100))
    local empty=$((width - filled))
    
    printf "\r${GREEN}%2d%% ${RESET}[${GREEN}"
    for ((i=0; i<filled; i++)); do printf "▓"; done
    for ((i=0; i<empty; i++)); do printf "░"; done
    printf "${RESET}]"
}

# 自动识别服务器IP地址
get_server_ip() {
    # 尝试多种方法获取公网IP
    # 方法1: 使用curl获取
    if command -v curl &> /dev/null; then
        PUBLIC_IP=$(curl -s ifconfig.me || curl -s icanhazip.com || curl -s ident.me)
        if [ ! -z "$PUBLIC_IP" ] && [[ "$PUBLIC_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            echo "$PUBLIC_IP"
            return 0
        fi
    fi
    
    # 方法2: 使用wget获取
    if command -v wget &> /dev/null; then
        PUBLIC_IP=$(wget -qO- ifconfig.me || wget -qO- icanhazip.com || wget -qO- ident.me)
        if [ ! -z "$PUBLIC_IP" ] && [[ "$PUBLIC_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            echo "$PUBLIC_IP"
            return 0
        fi
    fi
    
    # 方法3: 查找默认网络接口的IP
    if command -v ip &> /dev/null; then
        # 获取默认路由接口
        DEFAULT_INTERFACE=$(ip route | grep default | awk '{print $5}')
        if [ ! -z "$DEFAULT_INTERFACE" ]; then
            INTERFACE_IP=$(ip addr show "$DEFAULT_INTERFACE" | grep -oP 'inet \K[0-9.]+')
            if [ ! -z "$INTERFACE_IP" ]; then
                echo "$INTERFACE_IP"
                return 0
            fi
        fi
    fi
    
    # 如果以上方法都失败，返回提示文本
    echo "未检测到IP (请手动输入)"
    return 1
}

# 初始化进度
progress=0
show_progress $progress

# 检查是否以root用户运行
if [ "$(id -u)" != "0" ]; then
   echo -e "\n${RED}错误: 此脚本需要以root用户运行${RESET}"
   exit 1
fi

# 设置变量
INSTALL_DIR="/opt/socks5"
SERVER_SCRIPT="socks5_light.sh"
SERVICE_NAME="socks5-proxy"
PORT=1080  # 默认使用1080端口
GITHUB_REPO="https://raw.githubusercontent.com/username/socks5/master"

# 获取服务器IP
SERVER_IP=$(get_server_ip)

# 最小化更新系统包
show_progress $progress
apt update -qq
progress=15
show_progress $progress

# 安装必要工具
apt install -y -qq socat wget curl
progress=30
show_progress $progress

# 创建安装目录
mkdir -p $INSTALL_DIR
progress=45
show_progress $progress

# 从GitHub下载轻量级服务器脚本
# 尝试下载脚本，添加重试机制
MAX_RETRIES=3
retry_count=0
download_success=false

while [ $retry_count -lt $MAX_RETRIES ]; do
    retry_count=$((retry_count + 1))
    
    if wget -q -O "$INSTALL_DIR/$SERVER_SCRIPT" "$GITHUB_REPO/$SERVER_SCRIPT"; then
        download_success=true
        break
    else
        sleep 2  # 等待2秒后重试
    fi
done

# 如果下载失败，显示指定提示
if [ "$download_success" = false ] || [ ! -s "$INSTALL_DIR/$SERVER_SCRIPT" ]; then
    echo -e "\n${RED}错误: 无法获取服务器脚本${RESET}"
    exit 1
fi

# 设置执行权限
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
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=socks5-proxy

[Install]
WantedBy=multi-user.target
EOF

# 重新加载systemd配置和启动服务
systemctl daemon-reload > /dev/null 2>&1
systemctl enable $SERVICE_NAME > /dev/null 2>&1
systemctl start $SERVICE_NAME > /dev/null 2>&1
progress=75
show_progress $progress

# 自动配置防火墙开放端口
# 检查系统是否安装了ufw
if command -v ufw &> /dev/null; then
    if ufw status | grep -q "Status: active"; then
        ufw allow $PORT/tcp > /dev/null 2>&1
    fi
# 检查系统是否安装了iptables
elif command -v iptables &> /dev/null; then
    iptables -A INPUT -p tcp --dport $PORT -j ACCEPT > /dev/null 2>&1
    # 保存iptables规则
    if command -v netfilter-persistent &> /dev/null; then
        netfilter-persistent save > /dev/null 2>&1
    elif command -v service &> /dev/null && service iptables save &> /dev/null; then
        service iptables save > /dev/null 2>&1
    fi
fi

progress=100
show_progress $progress

# 新行结束进度条
echo

# 新行结束进度条
echo

# 显示安装完成信息 - 简约高级设计
echo -e "\n${CYAN}────────────────────────────────────────${RESET}"
echo -e "${GREEN}✓ 安装完成${RESET}"
echo -e "${CYAN}────────────────────────────────────────${RESET}"

# 代理配置信息 - 简约展示
cat << EOF
${BLUE}代理配置${RESET}
${YELLOW}┌─────────────┬─────────────────────┐${RESET}
${YELLOW}│${RESET} ${GREEN}协议类型${RESET} ${YELLOW}│${RESET} ${GREEN}Socks5${RESET}${YELLOW}            │${RESET}
${YELLOW}├─────────────┼─────────────────────┤${RESET}
${YELLOW}│${RESET} ${GREEN}服务器IP${RESET} ${YELLOW}│${RESET} ${GREEN}${SERVER_IP}${RESET}${YELLOW}│${RESET}
${YELLOW}├─────────────┼─────────────────────┤${RESET}
${YELLOW}│${RESET} ${GREEN}端口号  ${RESET} ${YELLOW}│${RESET} ${GREEN}${PORT}${RESET}${YELLOW}                │${RESET}
${YELLOW}├─────────────┼─────────────────────┤${RESET}
${YELLOW}│${RESET} ${GREEN}认证方式${RESET} ${YELLOW}│${RESET} ${GREEN}无需认证${RESET}${YELLOW}          │${RESET}
${YELLOW}└─────────────┴─────────────────────┘${RESET}
EOF

# 操作方式 - 精简展示
cat << EOF
${BLUE}服务管理${RESET}
${GREEN}• ${RESET}启动: ${GREEN}systemctl start ${SERVICE_NAME}${RESET}
${GREEN}• ${RESET}停止: ${GREEN}systemctl stop ${SERVICE_NAME}${RESET}
${GREEN}• ${RESET}重启: ${GREEN}systemctl restart ${SERVICE_NAME}${RESET}
${GREEN}• ${RESET}状态: ${GREEN}systemctl status ${SERVICE_NAME}${RESET}
EOF

echo -e "\n${CYAN}────────────────────────────────────────${RESET}"
