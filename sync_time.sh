#!/bin/bash

# 檢查是否為 root 權限
if [ "$EUID" -ne 0 ]; then 
  echo "請以 sudo 執行此腳本"
  exit
fi

echo "正在連線至 Google 獲取網路時間..."

# 從 Google 的 HTTP Header 抓取時間字串
# 格式範例：Fri, 03 Apr 2026 09:00:00 GMT
HTTP_TIME=$(curl -I --medir-time 5 http://www.google.com 2>&1 | grep -i '^date:' | cut -d' ' -f2-7)

if [ -n "$HTTP_TIME" ]; then
    echo "抓取到的時間為: $HTTP_TIME"
    
    # 設定系統時間 (-s 為 set)
    date -s "$HTTP_TIME" > /dev/null
    
    # 同步到硬體時鐘（防止重啟後跳回舊時間，視硬體支援而定）
    hwclock -w
    
    echo "時間同步完成！目前系統時間為: $(date)"
else
    echo "錯誤：無法連線至網路或抓取時間失敗。"
fi
