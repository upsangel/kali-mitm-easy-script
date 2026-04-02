#!/bin/bash

# ================= 配置區域 =================
TARGET_IP=""
PROXY_PORT=8080
WEB_PORT=8081
# 🔥 設定您的 Web 介面登入密碼
WEB_PASSWORD="asdfasdf"
LOG_FILE="/tmp/mitmweb.log"
# ===========================================

# 1. 檢查 Root 權限
if [ "$EUID" -ne 0 ]; then
  echo "❌ 請使用 sudo 運行此腳本"
  exit 1
fi

echo "🚀 正在啟動透明代理 MITM 模式..."

# 2. 確保內核參數正確
modprobe br_netfilter
sysctl -w net.bridge.bridge-nf-call-iptables=1 > /dev/null
sysctl -w net.ipv4.ip_forward=1 > /dev/null

# 3. 設置 nftables 規則
nft delete table ip mitm_nat 2>/dev/null

echo "🔧 配置 nftables 劫持規則..."
nft add table ip mitm_nat
nft add chain ip mitm_nat prerouting '{ type nat hook prerouting priority dstnat; policy accept; }'

if [ -z "$TARGET_IP" ]; then
    echo "   -> 模式: 監控所有設備"
    nft add rule ip mitm_nat prerouting "meta iifname \"br0\" tcp dport { 80, 443 } redirect to :$PROXY_PORT"
else
    echo "   -> 模式: 僅監控目標 IP [$TARGET_IP]"
    nft add rule ip mitm_nat prerouting "ip saddr $TARGET_IP tcp dport { 80, 443 } redirect to :$PROXY_PORT"
fi

# 4. 後台啟動 mitmweb
if pgrep -x "mitmweb" > /dev/null; then
    echo "⚠️  mitmweb 已經在運行中。"
    echo "📋 --- 當前日誌輸出 (最後 10 行) ---"
    tail -n 10 "$LOG_FILE"
    echo "------------------------"
else
    echo "🧹 清空舊日誌文件..."
    rm -f "$LOG_FILE"

    echo "PY  啟動 mitmweb (Web端口: $WEB_PORT)..."
    
    REAL_USER=${SUDO_USER:-$USER}
    
    # 🔥 核心修改：加入 --set web_password="$WEB_PASSWORD"
    # 注意：PYTHONUNBUFFERED=1 必須保留以確保日誌實時輸出
    sudo -u $REAL_USER nohup env PYTHONUNBUFFERED=1 mitmweb \
        --mode transparent \
        --showhost \
        --web-port $WEB_PORT \
        --web-host 0.0.0.0 \
        --set web_password="$WEB_PASSWORD" \
        --allow-hosts "^.*$" \
        > "$LOG_FILE" 2>&1 &
        
    sleep 4
    
    if pgrep -x "mitmweb" > /dev/null; then
        echo "✅ mitmweb 啟動成功！PID: $(pgrep -x mitmweb)"
        echo ""
        echo "📋 --- mitmweb 啟動日誌 ---"
        cat "$LOG_FILE"
        echo "--------------------------"
        
        if [ ! -s "$LOG_FILE" ]; then
            echo "⚠️  警告：日誌為空但進程運行中。"
        fi
        
    else
        echo "❌ mitmweb 啟動失敗，請查看完整日誌: cat $LOG_FILE"
        nft delete table ip mitm_nat
        exit 1
    fi
fi

# 獲取本機 IP
HOST_IP=$(hostname -I | awk '{print $1}')

echo "==============================================="
echo "✅ 劫持已開啟。"
echo "🌐 Web 控制台: http://$HOST_IP:$WEB_PORT"
echo "🔑 登入密碼: $WEB_PASSWORD"
echo "📂 日誌文件: $LOG_FILE"
echo "==============================================="