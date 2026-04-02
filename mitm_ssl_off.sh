#!/bin/bash

# 1. 检查 Root 权限
if [ "$EUID" -ne 0 ]; then
  echo "❌ 请使用 sudo 运行此脚本"
  exit 1
fi

echo "🛑 正在停止 MITM 模式..."

# 2. 清除防火墙规则
echo "🧹 清除 nftables 劫持规则..."
if nft list table ip mitm_nat >/dev/null 2>&1; then
    nft delete table ip mitm_nat
    echo "   -> 规则已删除，流量已恢复直连。"
else
    echo "   -> 未发现活动规则。"
fi

# 3. 停止 mitmweb 进程
echo "🔪 停止 mitmweb 进程..."
if pgrep -x "mitmweb" > /dev/null; then
    killall mitmweb
    echo "   -> mitmweb 已停止。"
else
    echo "   -> mitmweb 未运行。"
fi

echo "✅ 全部完成。现在是普通透明网桥模式。"