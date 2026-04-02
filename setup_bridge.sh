#!/bin/bash

# ==========================================
# 網路橋接器 (Network Bridge) 設定腳本
# 參考來源：https://www.youtube.com/watch?v=cYzNMMdKGG4
# ==========================================

echo "開始更新系統並安裝 bridge-utils 與 net-tools..."
sudo apt update
sudo apt install -y bridge-utils net-tools

echo "停止 NetworkManager 服務以避免設定衝突..."
sudo systemctl stop NetworkManager

echo "清除實體網卡 (eth0, eth1) 的 IP 並重啟網卡..."
sudo ifconfig eth0 0.0.0.0 down
sudo ifconfig eth1 0.0.0.0 down
sudo ifconfig eth0 0.0.0.0 up
sudo ifconfig eth1 0.0.0.0 up

echo "配置虛擬網橋 br0 並將 eth0, eth1 加入..."
sudo brctl addbr br0
sudo brctl addif br0 eth0
sudo brctl addif br0 eth1
sudo ifconfig br0 up

echo "正在為網橋 br0 獲取 IP 地址 (DHCP)..."
sudo dhclient br0

echo "開啟 IPv4 與 IPv6 的流量轉發功能..."
sudo sysctl -w net.ipv4.ip_forward=1
sudo sysctl -w net.ipv6.conf.all.forwarding=1

echo "設定完成！可使用 ifconfig 或 ip a 檢查 br0 狀態。"