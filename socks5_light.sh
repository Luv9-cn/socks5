#!/bin/bash

# 轻量级Socks5代理服务器 - Bash实现
# 仅支持CONNECT命令和无需认证

HOST="0.0.0.0"
PORT=1080  # 默认端口1080
BUFFER_SIZE=4096

# 检查参数
while getopts "h:p:" opt; do
  case "$opt" in
    h) HOST="$OPTARG" ;;
    p) PORT="$OPTARG" ;;
  esac
done

# 处理连接的函数
if [ "$1" = "--handle-connection" ]; then
  # 1. 握手阶段
  # 读取客户端握手请求
  read -r -n 1 version
  read -r -n 1 nmethods
  
  # 跳过客户端支持的认证方法
  dd bs=1 count="$(( $(printf '%d' "$nmethods") ))" 2>/dev/null
  
  # 发送无需认证的响应 (0x05 0x00)
  echo -en "\x05\x00"
  
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
    # 不支持的地址类型
    echo -en "\x05\x08\x00\x01\x00\x00\x00\x00\x00\x00"
    exit 1
  fi
  
  # 读取端口
  read -r -n 2 port_bytes
  port_high=$(printf '%d' "${port_bytes:0:1}")
  port_low=$(printf '%d' "${port_bytes:1:1}")
  target_port=$(( (port_high << 8) | port_low ))
  
  # 3. 连接目标服务器
  if [ "$cmd" -eq 1 ]; then  # CONNECT命令
    # 发送成功响应
    echo -en "\x05\x00\x00\x01\x00\x00\x00\x00\x00\x00"
    
    # 4. 数据转发
    # 使用socat进行双向转发
    exec socat - TCP4:"$target_addr:$target_port"
  else
    # 不支持的命令
    echo -en "\x05\x07\x00\x01\x00\x00\x00\x00\x00\x00"
    exit 1
  fi
else
  # 主程序 - 启动服务器
  echo -e "\e[1;32m[信息] Socks5轻量级代理服务器启动在 $HOST:$PORT\e[0m"
  
  # 使用socat创建服务器
  socat TCP4-LISTEN:$PORT,fork EXEC:"$0 --handle-connection",nofork
fi
