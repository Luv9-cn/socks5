#!/bin/bash

# 轻量级Socks5代理服务器一键安装脚本 (Debian 12)
echo -e "\e[1;36m========================================\e[0m"
echo -e "\e[1;34m轻量级Socks5代理服务器一键安装脚本\e[0m"
echo -e "\e[1;32m适用于 Debian 12\e[0m"
echo -e "\e[1;36m========================================\e[0m"

# 进度条函数
show_progress() {
    local width=30
    local percentage=$1
    local filled=$((percentage * width / 100))
    local empty=$((width - filled))
    
    printf "\r[\e[1;32m"
    for ((i=0; i<filled; i++)); do printf "█"; done
    for ((i=0; i<empty; i++)); do printf "░"; done
    printf "\e[0m] %3d%%" $percentage
}

# 初始化进度
progress=0
show_progress $progress

# 检查是否以root用户运行
if [ "$(id -u)" != "0" ]; then
   echo -e "\n\e[1;31m错误: 此脚本需要以root用户运行\e[0m"
   exit 1
fi

# 设置变量
INSTALL_DIR="/opt/socks5"
SERVER_SCRIPT="socks5_light.sh"
SERVICE_NAME="socks5-proxy"
PORT=1080  # 默认使用1080端口
GITHUB_REPO="https://raw.githubusercontent.com/Luv9-cn/socks5/master"

echo -e "\n\e[1;33m使用默认端口: $PORT\e[0m"

# 最小化更新系统包
echo -e "\e[1;33m[1/6] 更新软件包索引...\e[0m"
apt update -qq
progress=15
show_progress $progress

# 安装必要工具
echo -e "\e[1;33m[2/6] 安装必要工具...\e[0m"
apt install -y -qq socat wget
progress=30
show_progress $progress

# 创建安装目录
echo -e "\e[1;33m[3/6] 创建安装目录...\e[0m"
mkdir -p $INSTALL_DIR
progress=45
show_progress $progress

# 从GitHub下载轻量级服务器脚本
echo -e "\e[1;33m[4/6] 获取Socks5服务器脚本...\e[0m"
# 尝试下载脚本，添加重试机制
MAX_RETRIES=3
retry_count=0
download_success=false

echo -e "\e[0;37m  正在从GitHub下载...\e[0m"
while [ $retry_count -lt $MAX_RETRIES ]; do
    retry_count=$((retry_count + 1))
    
    if wget -q -O "$INSTALL_DIR/$SERVER_SCRIPT" "$GITHUB_REPO/$SERVER_SCRIPT"; then
        echo -e "\e[1;32m  ✓ 下载成功\e[0m"
        download_success=true
        break
    else
        echo -e "\e[1;31m  ✗ 下载失败 (尝试 $retry_count/$MAX_RETRIES)，正在重试...\e[0m"
        sleep 2  # 等待2秒后重试
    fi
done

# 如果下载失败，显示指定提示
if [ "$download_success" = false ]; then
    echo -e "\n\e[1;31m[错误] GitHub无法连接疑似作者跑路了\e[0m"
    exit 1
fi

# 验证下载的文件是否有效
if [ ! -s "$INSTALL_DIR/$SERVER_SCRIPT" ]; then
    echo -e "\n\e[1;31m[错误] GitHub无法连接疑似作者跑路了\e[0m"
    exit 1
fi

# 设置执行权限
chmod +x "$INSTALL_DIR/$SERVER_SCRIPT"
echo -e "\e[1;32m  ✓ 已设置脚本执行权限\e[0m"
progress=60
show_progress $progress

# 创建systemd服务文件
echo -e "\e[1;33m[5/6] 配置系统服务...\e[0m"
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
echo -e "\e[1;32m  ✓ 服务已配置并启动\e[0m"
progress=75
show_progress $progress

# 自动配置防火墙开放端口
echo -e "\e[1;33m[6/6] 配置防火墙...\e[0m"
firewall_status="\e[1;32m✓ 防火墙已配置\e[0m"

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

echo -e "\e[1;32m  $firewall_status\e[0m"
progress=100
show_progress $progress

# 新行结束进度条
echo

# 显示安装完成信息
echo -e "\e[1;36m========================================\e[0m"
echo -e "\e[1;32m✓ Socks5代理服务器安装完成!\e[0m"
echo -e "\e[1;36m========================================\e[0m"

# 代理配置信息
echo -e "\e[1;34m代理配置:\e[0m"
echo -e "  \e[1;33m地址类型: \e[1;32mSocks5\e[0m"
echo -e "  \e[1;33m服务器IP: \e[1;32m您的服务器IP\e[0m"
echo -e "  \e[1;33m端口号  : \e[1;32m$PORT\e[0m"
echo -e "  \e[1;33m认证方式: \e[1;32m无需认证\e[0m"
echo -e ""

# 操作方式
echo -e "\e[1;34m服务管理:\e[0m"
echo -e "  \e[1;32msystemctl start $SERVICE_NAME    # 启动服务\e[0m"
echo -e "  \e[1;32msystemctl stop $SERVICE_NAME     # 停止服务\e[0m"
echo -e "  \e[1;32msystemctl restart $SERVICE_NAME  # 重启服务\e[0m"
echo -e "  \e[1;32msystemctl status $SERVICE_NAME   # 查看状态\e[0m"
echo -e ""
echo -e "\e[1;36m========================================\e[0m"
