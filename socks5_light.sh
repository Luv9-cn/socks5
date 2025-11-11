#!/bin/bash

# 轻量级Socks5代理服务器 - Bash实现
# 仅支持CONNECT命令和无需认证

HOST="0.0.0.0"
PORT=1080
BUFFER_SIZE=4096

# 检查参数
while getopts "h:p:" opt; do
  case "$opt" in
    h) HOST="$OPTARG" ;;
    p) PORT="$OPTARG" ;;
  esac
done

echo "Socks5轻量级代理服务器启动在 $HOST:$PORT"

# 创建监听套接字
listener=$(socket -d -L -n -s $PORT)
if [ $? -ne 0 ]; then
  echo "错误: 无法创建监听套接字，请确保安装了socat工具"
  exit 1
fi

# 处理客户端连接
while true; do
  # 接受客户端连接
  client=$(echo "$listener" | socket -A -l -)
  if [ $? -ne 0 ]; then
    echo "接受连接失败，重试..."
    continue
  fi

  # 处理客户端连接的函数
  handle_connection() {
    local client_fd=$1
    local client_info="$2"
    
    echo "客户端连接: $client_info"
    
    # 1. 握手阶段
    # 读取客户端握手请求
    read -r -n 1 version
    read -r -n 1 nmethods
    
    # 跳过客户端支持的认证方法
    dd bs=1 count="$(( $(printf '%d' "$nmethods") ))" 2>/dev/null
    
    # 发送无需认证的响应 (0x05 0x00)
    echo -en "\x05\x00" >&$client_fd
    
    # 2. 请求阶段
    read -r -n 4 header
    version=$(printf '%d' "${header:0:1}")
    cmd=$(printf '%d' "${header:1:1}")
    rsv=$(printf '%d' "${header:2:1}")
    addr_type=$(printf '%d' "${header:3:1}")
    
    # 解析目标地址和端口
    if [ "$addr_type" -eq 1 ]; then  # IPv4
      read -r -n 4 ipv4
      target_addr="$(printf '%d.' "${ipv4:0:1}")$(printf '%d.' "${ipv4:1:1}")$(printf '%d.' "${ipv4:2:1}")$(printf '%d' "${ipv4:3:1}")"
    elif [ "$addr_type" -eq 3 ]; then  # 域名
      read -r -n 1 addr_len
      addr_len=$(printf '%d' "$addr_len")
      read -r -n "$addr_len" target_addr
    else
      echo "不支持的地址类型: $addr_type"
      return 1
    fi
    
    # 读取端口
    read -r -n 2 port_bytes
    port_high=$(printf '%d' "${port_bytes:0:1}")
    port_low=$(printf '%d' "${port_bytes:1:1}")
    target_port=$(( (port_high << 8) | port_low ))
    
    echo "连接请求: $target_addr:$target_port"
    
    # 3. 连接目标服务器
    if [ "$cmd" -eq 1 ]; then  # CONNECT命令
      # 使用socat连接目标服务器
      socat_fd=$(socat -d -d - TCP4:"$target_addr:$target_port" 2>&1)
      
      if [ $? -eq 0 ]; then
        # 发送成功响应
        echo -en "\x05\x00\x00\x01\x00\x00\x00\x00\x00\x00" >&$client_fd
        
        # 4. 数据转发 (简化版本，实际生产环境需要更复杂的处理)
        # 这里使用socat进行双向转发
        socat - "TCP4:$target_addr:$target_port" <&$client_fd >&$client_fd
      else
        # 发送失败响应
        echo -en "\x05\x05\x00\x01\x00\x00\x00\x00\x00\x00" >&$client_fd
        echo "连接目标服务器失败: $target_addr:$target_port"
      fi
    else
      # 不支持的命令
      echo -en "\x05\x07\x00\x01\x00\x00\x00\x00\x00\x00" >&$client_fd
      echo "不支持的命令: $cmd"
    fi
    
    echo "客户端连接关闭: $client_info"
  }
  
  # 在后台处理连接
  handle_connection "$client" "未知" &
done
