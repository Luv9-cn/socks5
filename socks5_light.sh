#!/bin/bash
HOST="0.0.0.0"
PORT=1080
while getopts "h:p:" opt; do
  case "$opt" in
    h) HOST="$OPTARG" ;;
    p) PORT="$OPTARG" ;;
  esac
done
if [ "$1" = "--handle-connection" ]; then
  read -r -n 1 version
  read -r -n 1 nmethods
  dd bs=1 count="$(( $(printf '%d' "$nmethods") ))" 2>/dev/null
  echo -en "\x05\x00"
  read -r -n 4 header
  version=$(printf '%d' "${header:0:1}")
  cmd=$(printf '%d' "${header:1:1}")
  rsv=$(printf '%d' "${header:2:1}")
  addr_type=$(printf '%d' "${header:3:1}")
  if [ "$addr_type" -eq 1 ]; then
    read -r -n 4 ipv4
    target_addr="$(printf '%d.' "${ipv4:0:1}")$(printf '%d.' "${ipv4:1:1}")$(printf '%d.' "${ipv4:2:1}")$(printf '%d' "${ipv4:3:1}")"
  elif [ "$addr_type" -eq 3 ]; then
    read -r -n 1 addr_len
    addr_len=$(printf '%d' "$addr_len")
    read -r -n "$addr_len" target_addr
  else
    echo -en "\x05\x08\x00\x01\x00\x00\x00\x00\x00\x00"
    exit 1
  fi
  read -r -n 2 port_bytes
  port_high=$(printf '%d' "${port_bytes:0:1}")
  port_low=$(printf '%d' "${port_bytes:1:1}")
  target_port=$(( (port_high << 8) | port_low ))
  if [ "$cmd" -eq 1 ]; then
    echo -en "\x05\x00\x00\x01\x00\x00\x00\x00\x00\x00"
    exec socat - TCP4:"$target_addr:$target_port"
  else
    echo -en "\x05\x07\x00\x01\x00\x00\x00\x00\x00\x00"
    exit 1
  fi
else
  socat TCP4-LISTEN:$PORT,fork EXEC:"$0 --handle-connection",nofork
fi
