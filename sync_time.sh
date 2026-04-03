#!/bin/bash

# 檢查是否為 root 權限
if [ "$EUID" -ne 0 ]; then 
  echo "請以 sudo 執行此腳本"
  exit
fi

echo "正在從 timeapi.io 獲取時間..."

# 根據 HackMD 文章的建議使用 timeapi.io
# 由於系統時間可能極度不準，導致 https 憑證失效，必須加上 -k (insecure) 忽略驗證
# 時區可以依照你的需求設定為 Asia/Hong_Kong 或 Asia/Taipei (皆為 +8)
URL="https://timeapi.io/api/time/current/zone?timeZone=Asia/Hong_Kong"

# 抓取資料並使用 tr 和 cut 來解析 JSON (避免系統沒安裝 jq)
# 會從 {"dateTime":"2026-04-03T17:20:16.647", ... } 中精準抽出時間字串
TIME_DATA=$(curl -s -k "$URL" | tr ',' '\n' | grep '"dateTime"' | cut -d '"' -f 4)

if [ -n "$TIME_DATA" ]; then
    echo "抓取到的時間為: $TIME_DATA"
    
    # 設定系統時間 (date 指令能完美識別這個 ISO 8601 格式字串)
    date -s "$TIME_DATA" > /dev/null
    
    # 同步到硬體時鐘
    hwclock -w
    
    echo "時間同步完成！目前系統時間為: $(date)"
else
    echo "錯誤：無法連線至 timeapi.io 或抓取時間失敗。"
fi
