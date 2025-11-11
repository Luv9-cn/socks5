#!/bin/bash

# 轻量级Socks5代理服务器一键安装脚本 (Debian 12)
echo -e "\e[1;36m========================================\e[0m"
echo -e "\e[1;34m轻量级Socks5代理服务器一键安装脚本\e[0m"
echo -e "\e[1;32m适用于 Debian 12 (快速安装版)\e[0m"
echo -e "\e[1;36m========================================\e[0m"

# 检查是否以root用户运行
if [ "$(id -u)" != "0" ]; then
   echo "错误: 此脚本需要以root用户运行"
   exit 1
fi

# 设置变量
INSTALL_DIR="/opt/socks5"
SERVER_SCRIPT="socks5_light.sh"
SERVICE_NAME="socks5-proxy"
PORT=1080  # 默认使用1080端口，无需用户输入
GITHUB_REPO="https://raw.githubusercontent.com/username/socks5/master"

echo -e "\e[1;33m[信息] 将使用默认端口: $PORT\e[0m"

# 最小化更新系统包，仅更新已安装包的索引而不升级所有包
echo -e "\e[1;33m[步骤 1/5] 更新软件包索引...\e[0m"
apt update -qq

# 安装必要工具，使用socat作为轻量级替代方案
echo -e "\e[1;33m[步骤 2/5] 安装必要工具...\e[0m"
apt install -y -qq socat wget

# 创建安装目录
echo -e "\e[1;33m[步骤 3/5] 创建安装目录: $INSTALL_DIR\e[0m"
mkdir -p $INSTALL_DIR

# 从GitHub下载轻量级服务器脚本
echo -e "\e[1;33m[步骤 4/5] 获取Socks5服务器脚本...\e[0m"
# 尝试下载脚本，添加重试机制
MAX_RETRIES=3
retry_count=0
download_success=false

while [ $retry_count -lt $MAX_RETRIES ]; do
    retry_count=$((retry_count + 1))
    echo -e "\e[1;32m  尝试下载 (尝试 $retry_count/$MAX_RETRIES)...\e[0m"
    
    if wget -q -O "$INSTALL_DIR/$SERVER_SCRIPT" "$GITHUB_REPO/$SERVER_SCRIPT"; then
        echo -e "\e[1;32m  下载成功！\e[0m"
        download_success=true
        break
    else
        echo -e "\e[1;31m  下载失败，正在重试...\e[0m"
        sleep 2  # 等待2秒后重试
    fi

done

# 如果下载失败，显示指定提示
if [ "$download_success" = false ]; then
    echo -e "\e[1;31m[错误] GitHub无法连接疑似作者跑路了\e[0m"
    exit 1
fi

# 验证下载的文件是否有效
if [ ! -s "$INSTALL_DIR/$SERVER_SCRIPT" ]; then
    echo -e "\e[1;31m[错误] GitHub无法连接疑似作者跑路了\e[0m"
    exit 1
fi

# 设置执行权限
chmod +x $INSTALL_DIR/$SERVER_SCRIPT
echo -e "\e[1;32m  已设置脚本执行权限\e[0m"

# 创建systemd服务文件
echo -e "\e[1;33m[步骤 5/5] 创建systemd服务...\e[0m"
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
echo -e "\e[1;32m  重新加载systemd配置...\e[0m"
systemctl daemon-reload

# 启用并启动服务
echo -e "\e[1;32m  启用并启动Socks5代理服务...\e[0m"
systemctl enable $SERVICE_NAME
systemctl start $SERVICE_NAME

# 检查服务状态
echo -e "\e[1;32m  检查服务状态...\e[0m"
systemctl status $SERVICE_NAME --no-pager

# 自动配置防火墙开放端口
echo -e "\e[1;33m[附加步骤] 配置防火墙开放端口 $PORT...\e[0m"
# 检查系统是否安装了ufw
if command -v ufw &> /dev/null; then
    if ufw status | grep -q "Status: active"; then
        ufw allow $PORT/tcp
        echo -e "\e[1;32m  已成功在ufw防火墙中开放端口 $PORT\e[0m"
    else
        echo -e "\e[1;33m  ufw防火墙未激活，跳过端口开放配置\e[0m"
    fi
# 检查系统是否安装了iptables
elif command -v iptables &> /dev/null; then
    iptables -A INPUT -p tcp --dport $PORT -j ACCEPT
    # 保存iptables规则（根据不同发行版可能需要调整）
    if command -v netfilter-persistent &> /dev/null; then
        netfilter-persistent save
    elif command -v service &> /dev/null && service iptables save &> /dev/null; then
        service iptables save
    else
        echo -e "\e[1;33m  已临时开放端口 $PORT，重启后可能需要重新配置\e[0m"
    fi
    echo -e "\e[1;32m  已成功在iptables中开放端口 $PORT\e[0m"
else
    echo -e "\e[1;33m  未检测到ufw或iptables，请确保手动开放端口 $PORT\e[0m"
fi

# 显示安装完成信息
echo -e "\e[1;36m========================================\e[0m"
echo -e "\e[1;32m✓ Socks5代理服务器安装完成!\e[0m"
echo -e "\e[1;36m========================================\e[0m"
echo -e "\e[1;34m服务信息:\e[0m"
echo -e "  \e[1;33m服务名称: \e[1;32m$SERVICE_NAME\e[0m"
echo -e "  \e[1;33m监听端口: \e[1;32m$PORT\e[0m"
echo -e "  \e[1;33m配置文件: \e[1;32m$INSTALL_DIR/$SERVER_SCRIPT\e[0m"
echo -e "  \e[1;33m服务文件: \e[1;32m/etc/systemd/system/$SERVICE_NAME.service\e[0m"
echo -e ""
echo -e "\e[1;34m服务管理命令:\e[0m"
echo -e "  \e[1;33m启动服务: \e[1;32msystemctl start $SERVICE_NAME\e[0m"
echo -e "  \e[1;33m停止服务: \e[1;32msystemctl stop $SERVICE_NAME\e[0m"
echo -e "  \e[1;33m重启服务: \e[1;32msystemctl restart $SERVICE_NAME\e[0m"
echo -e "  \e[1;33m查看状态: \e[1;32msystemctl status $SERVICE_NAME\e[0m"
echo -e "  \e[1;33m查看日志: \e[1;32mjournalctl -u $SERVICE_NAME -f\e[0m"
echo -e ""
echo -e "\e[1;34m使用信息:\e[0m"
echo -e "  \e[1;33mSocks5代理地址: \e[1;32msocks5://您的服务器IP:$PORT\e[0m"
echo -e "\e[1;36m========================================\e[0m"
