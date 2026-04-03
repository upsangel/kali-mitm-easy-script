#!/bin/bash

# 檢查是否為 root 權限
if [ "$EUID" -ne 0 ]; then 
  echo "請以 sudo 執行此腳本"
  exit
fi

# ==========================================
# 1. 時區設定區塊
# ==========================================
TARGET_TZ="Asia/Hong_Kong"
echo "正在檢查系統時區..."

# 嘗試獲取當前時區
CURRENT_TZ=$(timedatectl show --property=Timezone --value 2>/dev/null)

if [ "$CURRENT_TZ" != "$TARGET_TZ" ]; then
    echo "發現目前時區為 ${CURRENT_TZ:-未設定}，正在切換至 $TARGET_TZ..."
    
    # 優先使用 modern Linux 的 timedatectl
    if command -v timedatectl &> /dev/null; then
        timedatectl set-timezone "$TARGET_TZ"
    else
        # 備用方案：直接建立軟連結 (針對某些極度精簡的環境)
        ln -sf "/usr/share/zoneinfo/$TARGET_TZ" /etc/localtime
        echo "$TARGET_TZ" > /etc/timezone
    fi
    echo "✅ 時區設定完成！"
else
    echo "✅ 系統時區已是 $TARGET_TZ，無需更改。"
fi

echo "----------------------------------------"

# ==========================================
# 2. 網路時間同步區塊
# ==========================================
echo "正在從 timeapi.io 獲取時間..."

URL="https://timeapi.io/api/time/current/zone?timeZone=$TARGET_TZ"

# 加上 -k 忽略憑證，並用原生的 tr, grep, cut 解析 JSON
TIME_DATA=$(curl -s -k "$URL" | tr ',' '\n' | grep '"dateTime"' | cut -d '"' -f 4)

if [ -n "$TIME_DATA" ]; then
    echo "✅ 成功抓取時間: $TIME_DATA"
    
    # 設定系統時間
    date -s "$TIME_DATA" > /dev/null
    
    # 嘗試同步到硬體時鐘 (Live USB 環境下若沒有硬體寫入權限會報錯，但可忽略)
    hwclock -w 2>/dev/null
    
    echo "========================================"
    echo "🎉 時間與時區同步徹底完成！"
    echo "目前系統精確時間為: $(date)"
    echo "========================================"
else
    echo "❌ 錯誤：無法連線至 timeapi.io 或解析失敗。"
fi
