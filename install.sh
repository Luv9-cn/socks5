#!/bin/bash
GREEN="\e[1;32m"
BLUE="\e[1;34m"
CYAN="\e[1;36m"
PURPLE="\e[1;35m"
YELLOW="\e[1;33m"
RED="\e[1;31m"
WHITE="\e[1;37m"
RESET="\e[0m"
BOLD="\e[1m"
UNDERLINE="\e[4m"

display_header() {
    echo -e "${PURPLE}${BOLD}"
    echo -e "  ╭━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╮${RESET}"
    echo -e "  ╰╮${WHITE}${BOLD}        Socks5 代理服务器         ${PURPLE}${BOLD}╭╯${RESET}"
    echo -e "  ──┴───────────────────────────────────┴──${RESET}"
    echo -e "${RESET}"
}

show_progress() {
    local percentage=$1
    local width=40
    local filled=$((percentage * width / 100))
    local empty=$((width - filled))
    local progress_char="█"
    
    printf "\r${CYAN}[${RESET}"
    printf "${GREEN}"
    for ((i=0; i<filled; i++)); do printf "${progress_char}"; done
    printf "${WHITE}"
    for ((i=0; i<empty; i++)); do printf "░"; done
    printf "${CYAN}] ${YELLOW}%3d%%${RESET} ${BLUE}安装中...${RESET}" $percentage
}

get_server_ip() {
    if command -v curl &> /dev/null; then
        PUBLIC_IP=$(curl -s ifconfig.me || curl -s icanhazip.com || curl -s ident.me)
        if [ ! -z "$PUBLIC_IP" ] && [[ "$PUBLIC_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            echo "$PUBLIC_IP"
            return 0
        fi
    fi
    
    if command -v wget &> /dev/null; then
        PUBLIC_IP=$(wget -qO- ifconfig.me || wget -qO- icanhazip.com || wget -qO- ident.me)
        if [ ! -z "$PUBLIC_IP" ] && [[ "$PUBLIC_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            echo "$PUBLIC_IP"
            return 0
        fi
    fi
    
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
    
    echo "your-server-ip"
}

display_header

if [ "$(id -u)" != "0" ]; then
    echo -e "${RED}${BOLD}错误: ${RESET}${RED}此脚本需要以root用户运行${RESET}"
    exit 1
fi

progress=0
show_progress $progress

INSTALL_DIR="/opt/socks5"
SERVER_SCRIPT="socks5_light.sh"
SERVICE_NAME="socks5-proxy"
PORT=1080
GITHUB_REPO="https://raw.githubusercontent.com/Luv9-cn/socks5/master"

apt update -qq 2>/dev/null
progress=20
show_progress $progress
apt install -y -qq socat wget curl 2>/dev/null
progress=40
show_progress $progress

mkdir -p $INSTALL_DIR

if ! wget -q -O "$INSTALL_DIR/$SERVER_SCRIPT" "$GITHUB_REPO/$SERVER_SCRIPT"; then
    cat > "$INSTALL_DIR/$SERVER_SCRIPT" << 'EOF'
#!/bin/bash
PORT=1080
while getopts "p:" opt; do
  case $opt in
    p) PORT="$OPTARG" ;;
  esac
done
socat TCP4-LISTEN:$PORT,reuseaddr,fork PROXY:127.0.0.1:0.0.0.0:0,proxyport=$PORT
EOF
fi

chmod +x "$INSTALL_DIR/$SERVER_SCRIPT"
progress=60
show_progress $progress

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

systemctl daemon-reload > /dev/null 2>&1
systemctl enable $SERVICE_NAME > /dev/null 2>&1
systemctl start $SERVICE_NAME > /dev/null 2>&1
progress=85
show_progress $progress

if command -v ufw &> /dev/null && ufw status | grep -q "Status: active"; then
    ufw allow $PORT/tcp > /dev/null 2>&1
elif command -v iptables &> /dev/null; then
    iptables -A INPUT -p tcp --dport $PORT -j ACCEPT > /dev/null 2>&1
    (command -v netfilter-persistent &> /dev/null && netfilter-persistent save) > /dev/null 2>&1
fi

progress=100
show_progress $progress
echo

SERVER_IP=$(get_server_ip)

echo -e "\n${GREEN}${BOLD}✓ 安装完成!${RESET}\n"

echo -e "${PURPLE}${BOLD}╭─────────────────────────────────────────────╮${RESET}"
echo -e "${PURPLE}${BOLD}│${RESET} ${BLUE}${BOLD}📡  代理服务器配置信息  ${RESET}${PURPLE}${BOLD}│${RESET}"
echo -e "${PURPLE}${BOLD}├─────────────────────────────────────────────┤${RESET}"
echo -e "${PURPLE}${BOLD}│${RESET} ${YELLOW}协议:${RESET} ${GREEN}Socks5${RESET}${PURPLE}${BOLD}│${RESET}"
echo -e "${PURPLE}${BOLD}│${RESET} ${YELLOW}地址:${RESET} ${CYAN}${UNDERLINE}socks5://${SERVER_IP}:${PORT}${RESET}${PURPLE}${BOLD} │${RESET}"
echo -e "${PURPLE}${BOLD}│${RESET} ${YELLOW}认证:${RESET} ${GREEN}无需认证${RESET}${PURPLE}${BOLD}│${RESET}"
echo -e "${PURPLE}${BOLD}├─────────────────────────────────────────────┤${RESET}"
echo -e "${PURPLE}${BOLD}│${RESET} ${BLUE}${BOLD}⚙️  服务管理命令${RESET}${PURPLE}${BOLD}│${RESET}"
echo -e "${PURPLE}${BOLD}├─────────────────────────────────────────────┤${RESET}"
echo -e "${PURPLE}${BOLD}│${RESET} ${CYAN}systemctl [start|stop|restart] ${SERVICE_NAME}${RESET}${PURPLE}${BOLD} │${RESET}"
echo -e "${PURPLE}${BOLD}╰─────────────────────────────────────────────╯${RESET}"

echo -e "\n${GREEN}${BOLD}🎉  代理服务器已成功部署！${RESET}"
echo -e "${BLUE}💡  提示: ${RESET}${WHITE}请将代理地址复制到您的客户端进行配置${RESET}"
echo -e "\n${PURPLE}${BOLD}👨‍💻  作者: ${RESET}${BLUE}Socks5 Team${RESET}"
echo -e "${PURPLE}${BOLD}🔗  开源地址: ${RESET}${CYAN}https://github.com/username/socks5${RESET}"
