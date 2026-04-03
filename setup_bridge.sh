#!/bin/bash

# ==========================================
# 網路橋接器 (Network Bridge) 設定腳本
# 參考來源：https://www.hkepc.com/forum/viewthread.php?tid=2764392
# ==========================================

# 1. 檢查是否以 root 權限 (sudo) 執行
if [ "$EUID" -ne 0 ]; then
  echo "❌ 錯誤：權限不足。請使用 sudo 執行此腳本！"
  echo "👉 範例：sudo ./setup_bridge.sh"
  exit 1
fi

# 2. 檢查套件是否已經安裝
echo "檢查必要套件..."
if dpkg -s bridge-utils >/dev/null 2>&1 && dpkg -s net-tools >/dev/null 2>&1; then
  echo "✅ bridge-utils 與 net-tools 已安裝，跳過更新與安裝步驟。"
else
  echo "⏳ 發現缺少套件，開始更新系統並安裝 bridge-utils 與 net-tools..."
  apt update
  apt install -y bridge-utils net-tools
fi

echo "停止 NetworkManager 服務以避免設定衝突..."
systemctl stop NetworkManager

# 3. 開啟並啟動 nftables 服務
echo "啟用並啟動 nftables 服務..."
systemctl enable nftables
systemctl start nftables

echo "清除實體網卡 (eth0, eth1) 的 IP 並重啟網卡..."
ifconfig eth0 0.0.0.0 down
ifconfig eth1 0.0.0.0 down
ifconfig eth0 0.0.0.0 up
ifconfig eth1 0.0.0.0 up

echo "配置虛擬網橋 br0 並將 eth0, eth1 加入..."
brctl addbr br0
brctl addif br0 eth0
brctl addif br0 eth1
ifconfig br0 up

# 4. 使用 dhcpcd 獲取 IP
echo "正在為網橋 br0 獲取 IP 地址 (使用 dhcpcd)..."
dhcpcd br0

echo "開啟 IPv4 與 IPv6 的流量轉發功能..."
sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv6.conf.all.forwarding=1

echo "✅ 設定完成！可使用 ifconfig 或 ip a 檢查 br0 狀態。"
