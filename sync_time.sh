#!/bin/bash

# 檢查是否為 root 權限
if [ "$EUID" -ne 0 ]; then 
  echo "請以 sudo 執行此腳本"
  exit
fi

echo "正在從 World Time API 獲取時間..."

# 1. 使用 http 而非 https，避免系統時間偏差過大導致 SSL 憑證驗證失敗
# 2. /api/ip.txt 會根據你的 IP 自動返回包含時區的精準時間
TIME_DATA=$(curl -s --max-time 5 http://worldtimeapi.org/api/ip.txt | grep '^datetime:' | cut -d ' ' -f 2)

if [ -n "$TIME_DATA" ]; then
    echo "抓取到的時間為: $TIME_DATA"
    
    # 設定系統時間 (Linux date 可以完美識別 ISO 8601 格式，包含時區偏移)
    date -s "$TIME_DATA" > /dev/null
    
    # 同步到硬體時鐘
    hwclock -w
    
    echo "時間同步完成！目前系統時間為: $(date)"
else
    echo "錯誤：無法連線至網路或抓取時間失敗。"
fi
